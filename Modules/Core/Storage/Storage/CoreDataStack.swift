@preconcurrency import CoreData
import Foundation

public final class CoreDataStack: CoreDataStackProtocol, @unchecked Sendable {
    public let persistentContainer: NSPersistentContainer

    private let configuration: CoreDataStackConfiguration
    private let persistentStoreReloadCondition = NSCondition()
    private var isReloadingPersistentStores = false

    public init(configuration: CoreDataStackConfiguration) throws {
        self.configuration = configuration

        let managedObjectModel = try Self.makeManagedObjectModel(
            modelName: configuration.modelName,
            bundle: configuration.bundle,
            explicitModel: configuration.managedObjectModel
        )

        persistentContainer = NSPersistentContainer(
            name: configuration.modelName,
            managedObjectModel: managedObjectModel
        )

        persistentContainer.persistentStoreDescriptions = [
            try Self.makePersistentStoreDescription(from: configuration)
        ]

        try Self.loadPersistentStores(for: persistentContainer)
        configureContexts()
    }

    @MainActor
    public var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    public func newBackgroundContext() -> NSManagedObjectContext {
        waitUntilPersistentStoresAvailable()
        let context = persistentContainer.newBackgroundContext()
        configureBackgroundContext(context)
        return context
    }

    public func performBackgroundTask<T: Sendable>(
        _ block: @Sendable @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = newBackgroundContext()
        return try await perform(block, on: context)
    }

    public func performBackgroundTransaction<T: Sendable>(
        _ block: @Sendable @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = newBackgroundContext()

        return try await perform({ transactionContext in
            let value = try block(transactionContext)
            try transactionContext.saveIfNeeded()
            return value
        }, on: context)
    }

    @MainActor
    public func performViewContextTransaction<T>(
        _ block: (NSManagedObjectContext) throws -> T
    ) throws -> T {
        let value = try block(viewContext)
        try viewContext.saveIfNeeded()
        return value
    }

    @MainActor
    public func saveViewContextIfNeeded() throws {
        try viewContext.saveIfNeeded()
    }

    public func destroyAllData() async throws {
        let persistentStoreCoordinator = persistentContainer.persistentStoreCoordinator
        let persistentStoreDescriptions = persistentContainer.persistentStoreDescriptions
        beginPersistentStoreReload()
        defer { endPersistentStoreReload() }

        await MainActor.run {
            persistentContainer.viewContext.performAndWait {
                persistentContainer.viewContext.reset()
            }
        }

        for store in Array(persistentStoreCoordinator.persistentStores) {
            try persistentStoreCoordinator.remove(store)

            guard let storeURL = store.url else { continue }

            try destroyPersistentStoreFiles(
                at: storeURL,
                type: store.type
            )
        }

        persistentContainer.persistentStoreDescriptions = persistentStoreDescriptions
        try Self.loadPersistentStores(for: persistentContainer)
        configureContexts()
    }

    private func configureContexts() {
        let viewContext = persistentContainer.viewContext
        viewContext.name = "CoreDataStack.viewContext"
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = configuration.viewContextMergePolicy
        viewContext.shouldDeleteInaccessibleFaults = true
    }

    private func configureBackgroundContext(_ context: NSManagedObjectContext) {
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = configuration.backgroundContextMergePolicy
        context.shouldDeleteInaccessibleFaults = true
        context.undoManager = nil
    }

    private func perform<T: Sendable>(
        _ block: @Sendable @escaping (NSManagedObjectContext) throws -> T,
        on context: NSManagedObjectContext
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let value = try block(context)
                    continuation.resume(returning: value)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func waitUntilPersistentStoresAvailable() {
        persistentStoreReloadCondition.lock()
        defer { persistentStoreReloadCondition.unlock() }

        while isReloadingPersistentStores {
            persistentStoreReloadCondition.wait()
        }
    }

    private func beginPersistentStoreReload() {
        persistentStoreReloadCondition.lock()
        isReloadingPersistentStores = true
        persistentStoreReloadCondition.unlock()
    }

    private func endPersistentStoreReload() {
        persistentStoreReloadCondition.lock()
        isReloadingPersistentStores = false
        persistentStoreReloadCondition.broadcast()
        persistentStoreReloadCondition.unlock()
    }

    private static func makeManagedObjectModel(
        modelName: String,
        bundle: Bundle,
        explicitModel: NSManagedObjectModel?
    ) throws -> NSManagedObjectModel {
        if let explicitModel {
            return explicitModel
        }

        if let modelURL = bundle.url(forResource: modelName, withExtension: "momd"),
           let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) {
            return managedObjectModel
        }

        if let modelURL = bundle.url(forResource: modelName, withExtension: "mom"),
           let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) {
            return managedObjectModel
        }

        throw CoreDataStackError.managedObjectModelNotFound(
            modelName: modelName,
            bundleIdentifier: bundle.bundleIdentifier
        )
    }

    private static func makePersistentStoreDescription(
        from configuration: CoreDataStackConfiguration
    ) throws -> NSPersistentStoreDescription {
        let description = NSPersistentStoreDescription()
        description.type = configuration.storeType
        description.shouldAddStoreAsynchronously = configuration.shouldAddStoreAsynchronously
        description.shouldMigrateStoreAutomatically = configuration.shouldMigrateStoreAutomatically
        description.shouldInferMappingModelAutomatically = configuration.shouldInferMappingModelAutomatically

        if let storeURL = configuration.storeURL {
            description.url = storeURL
        } else if configuration.storeType == NSSQLiteStoreType {
            description.url = try makeDefaultSQLiteStoreURL(modelName: configuration.modelName)
        }

        return description
    }

    private static func makeDefaultSQLiteStoreURL(modelName: String) throws -> URL {
        let fileManager = FileManager.default
        let directoryURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL.appendingPathComponent("\(modelName).sqlite")
    }

    private static func loadPersistentStores(
        for persistentContainer: NSPersistentContainer
    ) throws {
        var loadError: Error?

        persistentContainer.loadPersistentStores { _, error in
            loadError = error
        }

        if let loadError {
            throw CoreDataStackError.persistentStoreLoadFailed(underlyingError: loadError)
        }
    }

    private func destroyPersistentStoreFiles(
        at storeURL: URL,
        type: String
    ) throws {
        guard type == NSSQLiteStoreType else {
            return
        }

        let fileManager = FileManager.default
        let sidecarExtensions = ["-shm", "-wal"]

        if fileManager.fileExists(atPath: storeURL.path) {
            try fileManager.removeItem(at: storeURL)
        }

        for extensionSuffix in sidecarExtensions {
            let sidecarURL = URL(fileURLWithPath: storeURL.path + extensionSuffix)
            if fileManager.fileExists(atPath: sidecarURL.path) {
                try fileManager.removeItem(at: sidecarURL)
            }
        }
    }
}
