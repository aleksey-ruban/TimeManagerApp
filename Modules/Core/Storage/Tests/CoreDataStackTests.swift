@preconcurrency import CoreData
import XCTest
@testable import CoreStorage

@MainActor
final class CoreDataStackTests: XCTestCase {
    func testViewContextTransactionPersistsInsertedObject() async throws {
        let stack = try makeInMemoryStack()

        try stack.performViewContextTransaction { context in
            let task = NSEntityDescription.insertNewObject(forEntityName: "Task", into: context)
            task.setValue("Inbox", forKey: "title")
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "Task")
        let tasks = try stack.viewContext.fetch(request)

        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.value(forKey: "title") as? String, "Inbox")
    }

    func testBackgroundTransactionSavesChangesVisibleInViewContext() async throws {
        let stack = try makeInMemoryStack()

        _ = try await stack.performBackgroundTransaction { context in
            let task = NSEntityDescription.insertNewObject(forEntityName: "Task", into: context)
            task.setValue("Focus", forKey: "title")
            return task.objectID
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "Task")
        let tasks = try stack.viewContext.fetch(request)

        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.value(forKey: "title") as? String, "Focus")
    }

    func testNewBackgroundContextUsesConfiguredMergePolicy() throws {
        let stack = try makeInMemoryStack()

        let backgroundContext = stack.newBackgroundContext()
        let mergePolicy = backgroundContext.mergePolicy as? NSMergePolicy

        XCTAssertEqual(mergePolicy?.mergeType, NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType)
        XCTAssertNil(backgroundContext.undoManager)
    }

    func testDestroyAllDataRemovesPersistedObjects() async throws {
        let stack = try makeInMemoryStack()

        try stack.performViewContextTransaction { context in
            let task = NSEntityDescription.insertNewObject(forEntityName: "Task", into: context)
            task.setValue("Archive", forKey: "title")
        }

        try await stack.destroyAllData()

        let request = NSFetchRequest<NSManagedObject>(entityName: "Task")
        let tasks = try stack.viewContext.fetch(request)

        XCTAssertTrue(tasks.isEmpty)
    }

    func testDestroyAllDataReloadsSQLiteStoreWithoutAddingDuplicateStore() async throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
        let stack = try CoreDataStack(
            configuration: CoreDataStackConfiguration(
                modelName: "TimeManagerApp",
                managedObjectModel: ManagedObjectModelFactory.makeTaskModel(),
                storeType: NSSQLiteStoreType,
                storeURL: storeURL,
                shouldAddStoreAsynchronously: false,
                shouldMigrateStoreAutomatically: false,
                shouldInferMappingModelAutomatically: false
            )
        )

        try stack.performViewContextTransaction { context in
            let task = NSEntityDescription.insertNewObject(forEntityName: "Task", into: context)
            task.setValue("Archive", forKey: "title")
        }

        try await stack.destroyAllData()

        let request = NSFetchRequest<NSManagedObject>(entityName: "Task")
        let tasks = try stack.viewContext.fetch(request)

        XCTAssertTrue(tasks.isEmpty)
        XCTAssertEqual(stack.persistentContainer.persistentStoreCoordinator.persistentStores.count, 1)
    }

    private func makeInMemoryStack() throws -> CoreDataStack {
        try CoreDataStack(
            configuration: .inMemory(
                modelName: "TimeManagerApp",
                managedObjectModel: ManagedObjectModelFactory.makeTaskModel()
            )
        )
    }
}
