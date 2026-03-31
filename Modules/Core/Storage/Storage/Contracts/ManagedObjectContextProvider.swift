@preconcurrency import CoreData

public protocol ManagedObjectContextProvider: AnyObject {
    @MainActor
    var viewContext: NSManagedObjectContext { get }

    func newBackgroundContext() -> NSManagedObjectContext
}
