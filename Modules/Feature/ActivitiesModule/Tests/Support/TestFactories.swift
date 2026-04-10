import Domain
import Foundation

enum TestFactories {
    static func category(
        id: UUID = UUID(),
        name: String,
        isDeleted: Bool = false
    ) -> Domain.Category {
        Domain.Category(
            localID: id,
            remoteID: nil,
            lastModifiedVersion: nil,
            baseName: name,
            code: nil,
            isDirty: false,
            isDeleted: isDeleted
        )
    }

    static func activityVariation(
        id: UUID = UUID(),
        value: String,
        position: Int,
        isDeleted: Bool = false
    ) -> ActivityVariation {
        ActivityVariation(
            localID: id,
            remoteID: nil,
            value: value,
            position: position,
            isDeleted: isDeleted
        )
    }

    static func activity(
        id: UUID = UUID(),
        name: String,
        categoryID: UUID? = nil,
        iconName: String = "bolt.fill",
        color: ActivityColor = .amber,
        variations: [ActivityVariation] = [],
        isDeleted: Bool = false
    ) -> Activity {
        Activity(
            localID: id,
            remoteID: nil,
            lastModifiedVersion: nil,
            name: name,
            categoryLocalID: categoryID,
            categoryRemoteID: nil,
            iconName: iconName,
            color: color,
            variations: variations,
            isDirty: false,
            isDeleted: isDeleted
        )
    }

    static func activityRecord(
        id: UUID = UUID(),
        activityID: UUID,
        variationID: UUID? = nil,
        startedAt: Date,
        endedAt: Date?,
        isDeleted: Bool = false
    ) -> ActivityRecord {
        ActivityRecord(
            localID: id,
            remoteID: nil,
            lastModifiedVersion: nil,
            activityLocalID: activityID,
            activityRemoteID: nil,
            variationLocalID: variationID,
            variationRemoteID: nil,
            startedAt: startedAt,
            endedAt: endedAt,
            timeZone: TimeZone(identifier: "Europe/Moscow")?.identifier ?? "Europe/Moscow",
            isDirty: false,
            isDeleted: isDeleted
        )
    }
}
