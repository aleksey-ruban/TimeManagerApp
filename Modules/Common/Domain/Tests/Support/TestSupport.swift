import CoreStorage
import Foundation

func makeInMemoryDomainCoreDataStack() throws -> CoreDataStack {
    try CoreDataStack(
        configuration: .inMemory(
            modelName: "DomainTests",
            managedObjectModel: DomainManagedObjectModelFactory.makeModel()
        )
    )
}
