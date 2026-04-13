import Foundation

public extension CategoryMO {
    func toDTO() -> Category {
        Category(
            localID: localID,
            remoteID: remoteIDValue,
            lastModifiedVersion: lastModifiedVersionValue,
            baseName: baseName,
            code: code,
            isDirty: isDirty,
            isDeleted: syncDeleted
        )
    }
}

public extension ActivityVariationMO {
    func toDTO() -> ActivityVariation {
        ActivityVariation(
            localID: localID,
            remoteID: remoteIDValue,
            value: value,
            position: Int(position),
            isDeleted: syncDeleted
        )
    }
}

public extension ActivityMO {
    func toDTO() -> Activity {
        let sortedVariations = (variations ?? [])
            .sorted { lhs, rhs in
                if lhs.position == rhs.position {
                    return lhs.localID.uuidString < rhs.localID.uuidString
                }
                return lhs.position < rhs.position
            }
            .map { $0.toDTO() }

        return Activity(
            localID: localID,
            remoteID: remoteIDValue,
            lastModifiedVersion: lastModifiedVersionValue,
            name: name,
            categoryLocalID: category?.localID,
            categoryRemoteID: category?.remoteIDValue,
            iconName: iconName,
            color: color,
            variations: sortedVariations,
            isDirty: isDirty,
            isDeleted: syncDeleted
        )
    }
}

public extension ActivityRecordMO {
    func toDTO() -> ActivityRecord {
        ActivityRecord(
            localID: localID,
            remoteID: remoteIDValue,
            lastModifiedVersion: lastModifiedVersionValue,
            activityLocalID: activity.localID,
            activityRemoteID: activity.remoteIDValue,
            variationLocalID: variation?.localID,
            variationRemoteID: variation?.remoteIDValue,
            startedAt: startedAt,
            endedAt: endedAt,
            timeZone: timeZone,
            isDirty: isDirty,
            isDeleted: syncDeleted
        )
    }
}

public extension CategorySnapshotMO {
    func toDTO() -> CategorySnapshot {
        CategorySnapshot(
            remoteID: remoteIDValue,
            globalCategoryID: globalCategoryIDValue,
            baseName: baseName,
            code: code
        )
    }
}

public extension ActivityVariationSnapshotMO {
    func toDTO() -> ActivityVariationSnapshot {
        ActivityVariationSnapshot(
            remoteID: remoteIDValue,
            globalActivityVariationID: globalActivityVariationIDValue,
            value: value
        )
    }
}

public extension ActivitySnapshotMO {
    func toDTO() -> ActivitySnapshot {
        let sortedVariations = (variationSnapshots ?? [])
            .sorted { lhs, rhs in
                lhs.value < rhs.value
            }
            .map { $0.toDTO() }

        return ActivitySnapshot(
            remoteID: remoteIDValue,
            globalActivityID: globalActivityIDValue,
            name: name,
            categorySnapshotRemoteID: categorySnapshot?.remoteIDValue,
            iconName: iconName,
            color: color,
            variations: sortedVariations
        )
    }
}

public extension ActivityRecordSnapshotMO {
    func toDTO() -> ActivityRecordSnapshot {
        ActivityRecordSnapshot(
            remoteID: remoteIDValue,
            globalActivityRecordID: globalActivityRecordIDValue,
            activitySnapshotRemoteID: activitySnapshot.remoteIDValue,
            variationSnapshotRemoteID: variationSnapshot?.remoteIDValue,
            startedAt: startedAt,
            endedAt: endedAt,
            timeZone: timeZone
        )
    }
}

public extension ChronometryMO {
    func toDTO() -> Chronometry {
        let categorySnapshotDTOs = (categorySnapshots ?? [])
            .sorted { lhs, rhs in
                lhs.baseName < rhs.baseName
            }
            .map { $0.toDTO() }

        let activitySnapshotDTOs = (activitySnapshots ?? [])
            .sorted { lhs, rhs in
                lhs.name < rhs.name
            }
            .map { $0.toDTO() }

        let activityRecordSnapshotDTOs = (activityRecordSnapshots ?? [])
            .sorted { lhs, rhs in
                lhs.startedAt < rhs.startedAt
            }
            .map { $0.toDTO() }

        return Chronometry(
            localID: localID,
            remoteID: remoteIDValue,
            lastModifiedVersion: lastModifiedVersionValue,
            startDate: startDate,
            endDate: endDate,
            isFinished: isFinished,
            timeZone: timeZone,
            categorySnapshots: categorySnapshotDTOs,
            activitySnapshots: activitySnapshotDTOs,
            activityRecordSnapshots: activityRecordSnapshotDTOs,
            isDirty: isDirty,
            isDeleted: syncDeleted
        )
    }
}
