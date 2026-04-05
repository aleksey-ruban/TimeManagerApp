@preconcurrency import CoreData
import Domain
import Foundation

enum DomainManagedObjectModelFactory {
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

        let record = NSEntityDescription()
        record.name = "ActivityRecordMO"
        record.managedObjectClassName = NSStringFromClass(ActivityRecordMO.self)

        let chronometry = NSEntityDescription()
        chronometry.name = "ChronometryMO"
        chronometry.managedObjectClassName = NSStringFromClass(ChronometryMO.self)

        let categorySnapshot = NSEntityDescription()
        categorySnapshot.name = "CategorySnapshotMO"
        categorySnapshot.managedObjectClassName = NSStringFromClass(CategorySnapshotMO.self)

        let activitySnapshot = NSEntityDescription()
        activitySnapshot.name = "ActivitySnapshotMO"
        activitySnapshot.managedObjectClassName = NSStringFromClass(ActivitySnapshotMO.self)

        let activityVariationSnapshot = NSEntityDescription()
        activityVariationSnapshot.name = "ActivityVariationSnapshotMO"
        activityVariationSnapshot.managedObjectClassName = NSStringFromClass(ActivityVariationSnapshotMO.self)

        let activityRecordSnapshot = NSEntityDescription()
        activityRecordSnapshot.name = "ActivityRecordSnapshotMO"
        activityRecordSnapshot.managedObjectClassName = NSStringFromClass(ActivityRecordSnapshotMO.self)

        let categoryActivities = relationship(
            name: "activities",
            destination: activity,
            minCount: 0,
            maxCount: 0,
            optional: true,
            deleteRule: .nullifyDeleteRule
        )
        let activityCategory = relationship(
            name: "category",
            destination: category,
            minCount: 0,
            maxCount: 1,
            optional: true,
            deleteRule: .nullifyDeleteRule
        )
        pair(categoryActivities, activityCategory)

        let activityVariations = relationship(
            name: "variations",
            destination: variation,
            minCount: 0,
            maxCount: 0,
            optional: true,
            deleteRule: .cascadeDeleteRule
        )
        let variationActivity = relationship(
            name: "activity",
            destination: activity,
            minCount: 1,
            maxCount: 1,
            optional: false,
            deleteRule: .nullifyDeleteRule
        )
        pair(activityVariations, variationActivity)

        let activityRecords = relationship(
            name: "records",
            destination: record,
            minCount: 0,
            maxCount: 0,
            optional: true,
            deleteRule: .nullifyDeleteRule
        )
        let recordActivity = relationship(
            name: "activity",
            destination: activity,
            minCount: 1,
            maxCount: 1,
            optional: false,
            deleteRule: .nullifyDeleteRule
        )
        pair(activityRecords, recordActivity)

        let variationRecords = relationship(
            name: "records",
            destination: record,
            minCount: 0,
            maxCount: 0,
            optional: true,
            deleteRule: .nullifyDeleteRule
        )
        let recordVariation = relationship(
            name: "variation",
            destination: variation,
            minCount: 0,
            maxCount: 1,
            optional: true,
            deleteRule: .nullifyDeleteRule
        )
        pair(variationRecords, recordVariation)

        let chronometryCategorySnapshots = relationship(
            name: "categorySnapshots",
            destination: categorySnapshot,
            minCount: 0,
            maxCount: 0,
            optional: true,
            deleteRule: .cascadeDeleteRule
        )
        let categorySnapshotChronometry = relationship(
            name: "chronometry",
            destination: chronometry,
            minCount: 1,
            maxCount: 1,
            optional: false,
            deleteRule: .nullifyDeleteRule
        )
        pair(chronometryCategorySnapshots, categorySnapshotChronometry)

        let chronometryActivitySnapshots = relationship(
            name: "activitySnapshots",
            destination: activitySnapshot,
            minCount: 0,
            maxCount: 0,
            optional: true,
            deleteRule: .cascadeDeleteRule
        )
        let activitySnapshotChronometry = relationship(
            name: "chronometry",
            destination: chronometry,
            minCount: 1,
            maxCount: 1,
            optional: false,
            deleteRule: .nullifyDeleteRule
        )
        pair(chronometryActivitySnapshots, activitySnapshotChronometry)

        let chronometryVariationSnapshots = relationship(
            name: "activityVariationSnapshots",
            destination: activityVariationSnapshot,
            minCount: 0,
            maxCount: 0,
            optional: true,
            deleteRule: .cascadeDeleteRule
        )
        let variationSnapshotChronometry = relationship(
            name: "chronometry",
            destination: chronometry,
            minCount: 1,
            maxCount: 1,
            optional: false,
            deleteRule: .nullifyDeleteRule
        )
        pair(chronometryVariationSnapshots, variationSnapshotChronometry)

        let chronometryRecordSnapshots = relationship(
            name: "activityRecordSnapshots",
            destination: activityRecordSnapshot,
            minCount: 0,
            maxCount: 0,
            optional: true,
            deleteRule: .cascadeDeleteRule
        )
        let recordSnapshotChronometry = relationship(
            name: "chronometry",
            destination: chronometry,
            minCount: 1,
            maxCount: 1,
            optional: false,
            deleteRule: .nullifyDeleteRule
        )
        pair(chronometryRecordSnapshots, recordSnapshotChronometry)

        let categorySnapshotActivities = relationship(
            name: "activitySnapshots",
            destination: activitySnapshot,
            minCount: 0,
            maxCount: 0,
            optional: true,
            deleteRule: .nullifyDeleteRule
        )
        let activitySnapshotCategorySnapshot = relationship(
            name: "categorySnapshot",
            destination: categorySnapshot,
            minCount: 0,
            maxCount: 1,
            optional: true,
            deleteRule: .nullifyDeleteRule
        )
        pair(categorySnapshotActivities, activitySnapshotCategorySnapshot)

        let activitySnapshotVariations = relationship(
            name: "variationSnapshots",
            destination: activityVariationSnapshot,
            minCount: 0,
            maxCount: 0,
            optional: true,
            deleteRule: .cascadeDeleteRule
        )
        let variationSnapshotActivity = relationship(
            name: "activitySnapshot",
            destination: activitySnapshot,
            minCount: 1,
            maxCount: 1,
            optional: false,
            deleteRule: .nullifyDeleteRule
        )
        pair(activitySnapshotVariations, variationSnapshotActivity)

        let activitySnapshotRecords = relationship(
            name: "activityRecordSnapshots",
            destination: activityRecordSnapshot,
            minCount: 0,
            maxCount: 0,
            optional: true,
            deleteRule: .nullifyDeleteRule
        )
        let recordSnapshotActivity = relationship(
            name: "activitySnapshot",
            destination: activitySnapshot,
            minCount: 1,
            maxCount: 1,
            optional: false,
            deleteRule: .nullifyDeleteRule
        )
        pair(activitySnapshotRecords, recordSnapshotActivity)

        let variationSnapshotRecords = relationship(
            name: "activityRecords",
            destination: activityRecordSnapshot,
            minCount: 0,
            maxCount: 0,
            optional: true,
            deleteRule: .nullifyDeleteRule
        )
        let recordSnapshotVariation = relationship(
            name: "variationSnapshot",
            destination: activityVariationSnapshot,
            minCount: 0,
            maxCount: 1,
            optional: true,
            deleteRule: .nullifyDeleteRule
        )
        pair(variationSnapshotRecords, recordSnapshotVariation)

        category.properties = [
            attribute("localID", .UUIDAttributeType),
            attribute("remoteID", .integer64AttributeType, optional: true),
            attribute("lastModifiedVersion", .integer64AttributeType, optional: true),
            attribute("baseName", .stringAttributeType),
            attribute("codeRawValue", .stringAttributeType, optional: true),
            attribute("isDirty", .booleanAttributeType),
            attribute("syncDeleted", .booleanAttributeType),
            categoryActivities,
        ]
        activity.properties = [
            attribute("localID", .UUIDAttributeType),
            attribute("remoteID", .integer64AttributeType, optional: true),
            attribute("lastModifiedVersion", .integer64AttributeType, optional: true),
            attribute("name", .stringAttributeType),
            attribute("iconName", .stringAttributeType),
            attribute("colorRawValue", .stringAttributeType),
            attribute("isDirty", .booleanAttributeType),
            attribute("syncDeleted", .booleanAttributeType),
            activityCategory,
            activityVariations,
            activityRecords,
        ]
        variation.properties = [
            attribute("localID", .UUIDAttributeType),
            attribute("remoteID", .integer64AttributeType, optional: true),
            attribute("value", .stringAttributeType),
            attribute("position", .integer64AttributeType),
            attribute("syncDeleted", .booleanAttributeType),
            variationActivity,
            variationRecords,
        ]
        record.properties = [
            attribute("localID", .UUIDAttributeType),
            attribute("remoteID", .integer64AttributeType, optional: true),
            attribute("lastModifiedVersion", .integer64AttributeType, optional: true),
            attribute("startedAt", .dateAttributeType),
            attribute("endedAt", .dateAttributeType, optional: true),
            attribute("timeZone", .stringAttributeType),
            attribute("isDirty", .booleanAttributeType),
            attribute("syncDeleted", .booleanAttributeType),
            recordActivity,
            recordVariation,
        ]
        chronometry.properties = [
            attribute("localID", .UUIDAttributeType),
            attribute("remoteID", .integer64AttributeType, optional: true),
            attribute("lastModifiedVersion", .integer64AttributeType, optional: true),
            attribute("startDate", .dateAttributeType),
            attribute("endDate", .dateAttributeType),
            attribute("isFinished", .booleanAttributeType),
            attribute("timeZone", .stringAttributeType),
            attribute("isDirty", .booleanAttributeType),
            attribute("syncDeleted", .booleanAttributeType),
            chronometryCategorySnapshots,
            chronometryActivitySnapshots,
            chronometryVariationSnapshots,
            chronometryRecordSnapshots,
        ]
        categorySnapshot.properties = [
            attribute("remoteID", .integer64AttributeType, optional: true),
            attribute("globalCategoryID", .integer64AttributeType, optional: true),
            attribute("baseName", .stringAttributeType),
            attribute("codeRawValue", .stringAttributeType, optional: true),
            categorySnapshotChronometry,
            categorySnapshotActivities,
        ]
        activitySnapshot.properties = [
            attribute("remoteID", .integer64AttributeType, optional: true),
            attribute("globalActivityID", .integer64AttributeType, optional: true),
            attribute("name", .stringAttributeType),
            attribute("iconName", .stringAttributeType),
            attribute("colorRawValue", .stringAttributeType),
            activitySnapshotChronometry,
            activitySnapshotCategorySnapshot,
            activitySnapshotVariations,
            activitySnapshotRecords,
        ]
        activityVariationSnapshot.properties = [
            attribute("remoteID", .integer64AttributeType, optional: true),
            attribute("globalActivityVariationID", .integer64AttributeType, optional: true),
            attribute("value", .stringAttributeType),
            variationSnapshotChronometry,
            variationSnapshotActivity,
            variationSnapshotRecords,
        ]
        activityRecordSnapshot.properties = [
            attribute("remoteID", .integer64AttributeType, optional: true),
            attribute("globalActivityRecordID", .integer64AttributeType, optional: true),
            attribute("startedAt", .dateAttributeType),
            attribute("endedAt", .dateAttributeType, optional: true),
            attribute("timeZone", .stringAttributeType),
            recordSnapshotChronometry,
            recordSnapshotActivity,
            recordSnapshotVariation,
        ]

        model.entities = [
            category, activity, variation, record,
            chronometry, categorySnapshot, activitySnapshot,
            activityVariationSnapshot, activityRecordSnapshot,
        ]
        return model
    }

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = false
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }

    private static func relationship(
        name: String,
        destination: NSEntityDescription?,
        minCount: Int,
        maxCount: Int,
        optional: Bool,
        deleteRule: NSDeleteRule
    ) -> NSRelationshipDescription {
        let relationship = NSRelationshipDescription()
        relationship.name = name
        relationship.destinationEntity = destination
        relationship.minCount = minCount
        relationship.maxCount = maxCount
        relationship.isOptional = optional
        relationship.deleteRule = deleteRule
        return relationship
    }

    private static func pair(_ lhs: NSRelationshipDescription, _ rhs: NSRelationshipDescription) {
        lhs.inverseRelationship = rhs
        rhs.inverseRelationship = lhs
    }
}
