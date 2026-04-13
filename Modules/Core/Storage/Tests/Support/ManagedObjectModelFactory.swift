@preconcurrency import CoreData

enum ManagedObjectModelFactory {
    static func makeTaskModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "Task"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = "title"
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = false

        entity.properties = [titleAttribute]
        model.entities = [entity]

        return model
    }
}
