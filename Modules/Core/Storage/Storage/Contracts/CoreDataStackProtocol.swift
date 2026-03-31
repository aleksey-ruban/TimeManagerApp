@preconcurrency import CoreData

public protocol CoreDataStackProtocol: ManagedObjectContextProvider {
    var persistentContainer: NSPersistentContainer { get }

    func performBackgroundTask<T: Sendable>(
        _ block: @Sendable @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T

    func performBackgroundTransaction<T: Sendable>(
        _ block: @Sendable @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T

    @MainActor
    func performViewContextTransaction<T>(
        _ block: (NSManagedObjectContext) throws -> T
    ) throws -> T

    @MainActor
    func saveViewContextIfNeeded() throws
}
