import Domain
import Foundation

private extension Domain.Category {
    var syncOperation: SyncOperationDTO {
        if remoteID == nil { return .create }
        return isDeleted ? .delete : .update
    }
}

private extension Domain.Activity {
    var syncOperation: SyncOperationDTO {
        if remoteID == nil { return .create }
        return isDeleted ? .delete : .update
    }
}

private extension Domain.ActivityRecord {
    var syncOperation: SyncOperationDTO {
        if remoteID == nil { return .create }
        return isDeleted ? .delete : .update
    }
}

private extension Domain.Chronometry {
    var syncOperation: SyncOperationDTO {
        if remoteID == nil { return .create }
        return isDeleted ? .delete : .update
    }
}

extension RemoteCategorySnapshotDTO {
    init(_ snapshot: Domain.CategorySnapshot) {
        self.init(
            id: snapshot.remoteID,
            baseName: snapshot.baseName,
            code: snapshot.code,
            globalCategoryId: snapshot.globalCategoryID
        )
    }
}

extension RemoteActivitySnapshotDTO {
    init(_ snapshot: Domain.ActivitySnapshot, categorySnapshotLookup: [Int64?: Int64?]) {
        self.init(
            id: snapshot.remoteID,
            globalActivityId: snapshot.globalActivityID,
            name: snapshot.name,
            categorySnapshotId: categorySnapshotLookup[snapshot.categorySnapshotRemoteID] ?? snapshot.categorySnapshotRemoteID,
            icon: snapshot.iconName,
            iconColor: snapshot.color.rawValue
        )
    }
}

extension RemoteActivityVariationSnapshotDTO {
    init(_ snapshot: Domain.ActivityVariationSnapshot, activitySnapshotId: Int64?) {
        self.init(
            id: snapshot.remoteID,
            globalActivityVariationId: snapshot.globalActivityVariationID,
            value: snapshot.value,
            activitySnapshotId: activitySnapshotId
        )
    }
}

extension RemoteActivityRecordSnapshotDTO {
    init(_ snapshot: Domain.ActivityRecordSnapshot) {
        self.init(
            id: snapshot.remoteID,
            globalActivityRecordId: snapshot.globalActivityRecordID,
            activitySnapshotId: snapshot.activitySnapshotRemoteID,
            variationSnapshotId: snapshot.variationSnapshotRemoteID,
            startedAt: snapshot.startedAt,
            endedAt: snapshot.endedAt,
            timeZone: snapshot.timeZone
        )
    }
}

extension RemoteChronometryDTO {
    init(_ chronometry: Domain.Chronometry) {
        let categorySnapshots = chronometry.categorySnapshots.map(RemoteCategorySnapshotDTO.init)
        let activitySnapshots = chronometry.activitySnapshots.map {
            RemoteActivitySnapshotDTO($0, categorySnapshotLookup: [:])
        }
        let variationSnapshots = chronometry.activitySnapshots.flatMap { activity in
            activity.variations.map { RemoteActivityVariationSnapshotDTO($0, activitySnapshotId: activity.remoteID) }
        }

        self.init(
            id: chronometry.remoteID ?? 0,
            startDate: Self.dayFormatter.string(from: chronometry.startDate),
            endDate: Self.dayFormatter.string(from: chronometry.endDate),
            timeZone: chronometry.timeZone,
            lastModifiedVersion: chronometry.lastModifiedVersion ?? 0,
            deleted: chronometry.isDeleted,
            categorySnapshotList: categorySnapshots,
            activitySnapshotList: activitySnapshots,
            activityVariationSnapshotList: variationSnapshots,
            activityRecordSnapshotList: chronometry.activityRecordSnapshots.map(RemoteActivityRecordSnapshotDTO.init)
        )
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

extension Domain.Category {
    func makePushRequestObject() -> SyncPushRequestObjectDTO {
        let payload = if let remoteID, let lastModifiedVersion {
            AnyEncodable(
                UpdateCategoryPayloadDTO(
                    id: remoteID,
                    baseName: baseName,
                    lastModifiedVersion: lastModifiedVersion,
                    deleted: isDeleted
                )
            )
        } else {
            AnyEncodable(
                CreateCategoryPayloadDTO(
                    baseName: baseName,
                    deleted: isDeleted
                )
            )
        }

        return SyncPushRequestObjectDTO(
            localId: localID,
            operation: syncOperation,
            objectType: .category,
            payload: payload
        )
    }
}

extension Domain.ActivityVariation {
    fileprivate func makeCreatePayload() -> CreateActivityVariationPayloadDTO {
        CreateActivityVariationPayloadDTO(
            position: position,
            value: value,
            deleted: isDeleted
        )
    }

    fileprivate func makeUpdatePayload() -> UpdateActivityVariationPayloadDTO {
        UpdateActivityVariationPayloadDTO(
            id: remoteID,
            position: position,
            value: value,
            deleted: isDeleted
        )
    }
}

extension Domain.Activity {
    func makePushRequestObject() -> SyncPushRequestObjectDTO {
        let payload = if let remoteID, let lastModifiedVersion {
            AnyEncodable(
                UpdateActivityPayloadDTO(
                    id: remoteID,
                    lastModifiedVersion: lastModifiedVersion,
                    name: name,
                    icon: iconName,
                    iconColor: color.rawValue,
                    categoryId: categoryRemoteID,
                    variations: variations.map { $0.makeUpdatePayload() },
                    deleted: isDeleted
                )
            )
        } else {
            AnyEncodable(
                CreateActivityPayloadDTO(
                    name: name,
                    icon: iconName,
                    iconColor: color.rawValue,
                    categoryId: categoryRemoteID,
                    variations: variations.map { $0.makeCreatePayload() },
                    deleted: isDeleted
                )
            )
        }

        return SyncPushRequestObjectDTO(
            localId: localID,
            operation: syncOperation,
            objectType: .activity,
            payload: payload
        )
    }
}

extension Domain.ActivityRecord {
    func makePushRequestObject() -> SyncPushRequestObjectDTO {
        let payload = if let remoteID, let lastModifiedVersion {
            AnyEncodable(
                UpdateActivityRecordPayloadDTO(
                    id: remoteID,
                    variationId: variationRemoteID,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    timeZone: timeZone,
                    deleted: isDeleted,
                    lastModifiedVersion: lastModifiedVersion
                )
            )
        } else {
            AnyEncodable(
                CreateActivityRecordPayloadDTO(
                    activityId: activityRemoteID ?? 0,
                    variationId: variationRemoteID,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    timeZone: timeZone,
                    deleted: isDeleted
                )
            )
        }

        return SyncPushRequestObjectDTO(
            localId: localID,
            operation: syncOperation,
            objectType: .activityRecord,
            payload: payload
        )
    }
}

extension Domain.Chronometry {
    func makePushRequestObject(localeIdentifier: String = Locale.current.identifier) -> SyncPushRequestObjectDTO {
        let payload = if let remoteID {
            AnyEncodable(
                FinishChronometryPayloadDTO(
                    id: remoteID,
                    finishTime: endDate,
                    local: localeIdentifier,
                    timeZone: timeZone,
                    snapshotVersion: SnapshotVersion(lastModifiedVersion ?? Int64(0)),
                    deleted: isDeleted
                )
            )
        } else {
            AnyEncodable(
                CreateChronometryPayloadDTO(
                    createTime: startDate,
                    timeZone: timeZone,
                    deleted: isDeleted
                )
            )
        }

        return SyncPushRequestObjectDTO(
            localId: localID,
            operation: syncOperation,
            objectType: .chronometrySnapshot,
            payload: payload
        )
    }
}
