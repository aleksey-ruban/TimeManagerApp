@preconcurrency import CoreData
import Domain
import Foundation

enum CommonSyncManagedObjectModelFactory {
    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let category = NSEntityDescription()
        category.name = "CategoryMO"
        category.managedObjectClassName = NSStringFromClass(CategoryMO.self)

        let activity = NSEntityDescription()
        activity.name = "ActivityMO"
        activity.managedObjectClassName = NSStringFromClass(ActivityMO.self)

        let variation = NSEntityDescription()
        variation.name = "ActivityVariationMO"
        variation.managedObjectClassName = NSStringFromClass(ActivityVariationMO.self)

        let categoryLocalID = makeAttribute(name: "localID", type: .UUIDAttributeType)
        let categoryRemoteID = makeAttribute(name: "remoteID", type: .integer64AttributeType, optional: true)
        let categoryLastModifiedVersion = makeAttribute(name: "lastModifiedVersion", type: .integer64AttributeType, optional: true)
        let categoryBaseName = makeAttribute(name: "baseName", type: .stringAttributeType)
        let categoryCodeRawValue = makeAttribute(name: "codeRawValue", type: .stringAttributeType, optional: true)
        let categoryIsDirty = makeAttribute(name: "isDirty", type: .booleanAttributeType)
        let categorySyncDeleted = makeAttribute(name: "syncDeleted", type: .booleanAttributeType)

        let activityLocalID = makeAttribute(name: "localID", type: .UUIDAttributeType)
        let activityRemoteID = makeAttribute(name: "remoteID", type: .integer64AttributeType, optional: true)
        let activityLastModifiedVersion = makeAttribute(name: "lastModifiedVersion", type: .integer64AttributeType, optional: true)
        let activityName = makeAttribute(name: "name", type: .stringAttributeType)
        let activityIconName = makeAttribute(name: "iconName", type: .stringAttributeType)
        let activityColorRawValue = makeAttribute(name: "colorRawValue", type: .stringAttributeType)
        let activityIsDirty = makeAttribute(name: "isDirty", type: .booleanAttributeType)
        let activitySyncDeleted = makeAttribute(name: "syncDeleted", type: .booleanAttributeType)

        let variationLocalID = makeAttribute(name: "localID", type: .UUIDAttributeType)
        let variationRemoteID = makeAttribute(name: "remoteID", type: .integer64AttributeType, optional: true)
        let variationValue = makeAttribute(name: "value", type: .stringAttributeType)
        let variationPosition = makeAttribute(name: "position", type: .integer64AttributeType)
        let variationSyncDeleted = makeAttribute(name: "syncDeleted", type: .booleanAttributeType)

        let categoryActivities = NSRelationshipDescription()
        categoryActivities.name = "activities"
        categoryActivities.destinationEntity = activity
        categoryActivities.minCount = 0
        categoryActivities.maxCount = 0
        categoryActivities.isOptional = true
        categoryActivities.deleteRule = .nullifyDeleteRule

        let activityCategory = NSRelationshipDescription()
        activityCategory.name = "category"
        activityCategory.destinationEntity = category
        activityCategory.minCount = 0
        activityCategory.maxCount = 1
        activityCategory.isOptional = true
        activityCategory.deleteRule = .nullifyDeleteRule

        categoryActivities.inverseRelationship = activityCategory
        activityCategory.inverseRelationship = categoryActivities

        let activityVariations = NSRelationshipDescription()
        activityVariations.name = "variations"
        activityVariations.destinationEntity = variation
        activityVariations.minCount = 0
        activityVariations.maxCount = 0
        activityVariations.isOptional = true
        activityVariations.deleteRule = .cascadeDeleteRule

        let variationActivity = NSRelationshipDescription()
        variationActivity.name = "activity"
        variationActivity.destinationEntity = activity
        variationActivity.minCount = 1
        variationActivity.maxCount = 1
        variationActivity.isOptional = false
        variationActivity.deleteRule = .nullifyDeleteRule

        activityVariations.inverseRelationship = variationActivity
        variationActivity.inverseRelationship = activityVariations

        let activityRecords = NSRelationshipDescription()
        activityRecords.name = "records"
        activityRecords.destinationEntity = nil
        activityRecords.minCount = 0
        activityRecords.maxCount = 0
        activityRecords.isOptional = true
        activityRecords.deleteRule = .nullifyDeleteRule

        let variationRecords = NSRelationshipDescription()
        variationRecords.name = "records"
        variationRecords.destinationEntity = nil
        variationRecords.minCount = 0
        variationRecords.maxCount = 0
        variationRecords.isOptional = true
        variationRecords.deleteRule = .nullifyDeleteRule

        category.properties = [
            categoryLocalID,
            categoryRemoteID,
            categoryLastModifiedVersion,
            categoryBaseName,
            categoryCodeRawValue,
            categoryIsDirty,
            categorySyncDeleted,
            categoryActivities,
        ]

        activity.properties = [
            activityLocalID,
            activityRemoteID,
            activityLastModifiedVersion,
            activityName,
            activityIconName,
            activityColorRawValue,
            activityIsDirty,
            activitySyncDeleted,
            activityCategory,
            activityVariations,
            activityRecords,
        ]

        variation.properties = [
            variationLocalID,
            variationRemoteID,
            variationValue,
            variationPosition,
            variationSyncDeleted,
            variationActivity,
            variationRecords,
        ]

        model.entities = [category, activity, variation]
        return model
    }

    private static func makeAttribute(
        name: String,
        type: NSAttributeType,
        optional: Bool = false
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
}
