import CoreData
import CoreStorage
import Domain
import Foundation

final class ChronometrySyncRepository: @unchecked Sendable {
    private let coreDataStack: CoreDataStackProtocol

    init(coreDataStack: CoreDataStackProtocol) {
        self.coreDataStack = coreDataStack
    }

    func fetchDirty() async throws -> [Chronometry] {
        try await coreDataStack.performBackgroundTask { context in
            let request = ChronometryMO.fetchRequest()
            request.predicate = NSPredicate(format: "isDirty == YES")
            request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func applyRemote(_ chronometries: [RemoteChronometryDTO]) async throws -> Int {
        try await coreDataStack.performBackgroundTransaction { [self] context in
            var applied = 0

            for remote in chronometries {
                let existing = try self.resolveUniqueChronometry(remoteID: remote.id, context: context)
                let localVersion = existing?.lastModifiedVersionValue ?? .min

                if existing != nil, remote.lastModifiedVersion <= localVersion {
                    continue
                }

                let object = existing ?? ChronometryMO(context: context)
                if existing == nil {
                    object.localID = UUID()
                }

                try self.apply(remote, to: object, context: context)
                applied += 1
            }

            return applied
        }
    }

    func acknowledgePush(_ acknowledgements: [ChronometryPushAcknowledgement]) async throws -> Int {
        try await coreDataStack.performBackgroundTransaction { context in
            var updated = 0

            for ack in acknowledgements {
                let request = ChronometryMO.fetchRequest()
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "localID == %@", ack.localID as CVarArg)

                guard let object = try context.fetch(request).first else { continue }
                object.remoteID = ack.remoteID.map(NSNumber.init(value:))
                object.lastModifiedVersion = ack.lastModifiedVersion.map(NSNumber.init(value:))
                object.isDirty = false
                updated += 1
            }

            return updated
        }
    }

    private func apply(
        _ remote: RemoteChronometryDTO,
        to object: ChronometryMO,
        context: NSManagedObjectContext
    ) throws {
        object.remoteID = NSNumber(value: remote.id)
        object.lastModifiedVersion = NSNumber(value: remote.lastModifiedVersion)
        object.startDate = try SyncDateCodec.day(from: remote.startDate)
        object.endDate = try SyncDateCodec.day(from: remote.endDate)
        object.timeZone = remote.timeZone
        object.isFinished = remote.finished
        object.syncDeleted = remote.deleted
        object.isDirty = false

        clearSnapshots(from: object, context: context)

        let categorySnapshots = remote.categorySnapshotList.map { dto -> CategorySnapshotMO in
            let snapshot = CategorySnapshotMO(context: context)
            snapshot.remoteID = dto.id.map(NSNumber.init(value:))
            snapshot.globalCategoryID = dto.globalCategoryId.map(NSNumber.init(value:))
            snapshot.baseName = dto.baseName
            snapshot.code = dto.code
            snapshot.chronometry = object
            return snapshot
        }

        let categoryByRemoteID = Dictionary(uniqueKeysWithValues: categorySnapshots.map { (($0.remoteIDValue ?? -1), $0) })

        let activitySnapshots = remote.activitySnapshotList.map { dto -> ActivitySnapshotMO in
            let snapshot = ActivitySnapshotMO(context: context)
            snapshot.remoteID = dto.id.map(NSNumber.init(value:))
            snapshot.globalActivityID = dto.globalActivityId.map(NSNumber.init(value:))
            snapshot.name = dto.name
            snapshot.iconName = dto.icon
            snapshot.colorRawValue = dto.iconColor
            snapshot.chronometry = object
            if let categorySnapshotId = dto.categorySnapshotId {
                snapshot.categorySnapshot = categoryByRemoteID[categorySnapshotId]
            }
            return snapshot
        }

        let activityByRemoteID = Dictionary(uniqueKeysWithValues: activitySnapshots.map { (($0.remoteIDValue ?? -1), $0) })

        let variationSnapshots = remote.activityVariationSnapshotList.compactMap { dto -> ActivityVariationSnapshotMO? in
            let snapshot = ActivityVariationSnapshotMO(context: context)
            snapshot.remoteID = dto.id.map(NSNumber.init(value:))
            snapshot.globalActivityVariationID = dto.globalActivityVariationId.map(NSNumber.init(value:))
            snapshot.value = dto.value
            snapshot.chronometry = object
            guard let activitySnapshot = resolveActivitySnapshot(
                remoteActivitySnapshotID: dto.activitySnapshotId,
                activityByRemoteID: activityByRemoteID,
                allSnapshots: activitySnapshots
            ) else {
                context.delete(snapshot)
                return nil
            }
            snapshot.activitySnapshot = activitySnapshot
            return snapshot
        }

        let variationByRemoteID: [Int64: ActivityVariationSnapshotMO] = Dictionary(uniqueKeysWithValues: variationSnapshots.compactMap { snapshot in
            snapshot.remoteIDValue.map { ($0, snapshot) }
        })

        _ = remote.activityRecordSnapshotList.map { dto -> ActivityRecordSnapshotMO in
            let snapshot = ActivityRecordSnapshotMO(context: context)
            snapshot.remoteID = dto.id.map(NSNumber.init(value:))
            snapshot.globalActivityRecordID = dto.globalActivityRecordId.map(NSNumber.init(value:))
            snapshot.startedAt = dto.startedAt
            snapshot.endedAt = dto.endedAt
            snapshot.timeZone = dto.timeZone
            snapshot.chronometry = object
            guard let activitySnapshot = resolveActivitySnapshot(
                remoteActivitySnapshotID: dto.activitySnapshotId,
                activityByRemoteID: activityByRemoteID,
                allSnapshots: activitySnapshots
            ) else {
                context.delete(snapshot)
                return snapshot
            }
            snapshot.activitySnapshot = activitySnapshot
            if let variationSnapshotId = dto.variationSnapshotId {
                snapshot.variationSnapshot = variationByRemoteID[variationSnapshotId]
            }
            return snapshot
        }
    }

    private func resolveActivitySnapshot(
        remoteActivitySnapshotID: Int64?,
        activityByRemoteID: [Int64: ActivitySnapshotMO],
        allSnapshots: [ActivitySnapshotMO]
    ) -> ActivitySnapshotMO? {
        if let remoteActivitySnapshotID {
            return activityByRemoteID[remoteActivitySnapshotID]
        }

        return allSnapshots.first
    }

    private func clearSnapshots(
        from chronometry: ChronometryMO,
        context: NSManagedObjectContext
    ) {
        (chronometry.activityRecordSnapshots ?? []).forEach(context.delete)
        (chronometry.activityVariationSnapshots ?? []).forEach(context.delete)
        (chronometry.activitySnapshots ?? []).forEach(context.delete)
        (chronometry.categorySnapshots ?? []).forEach(context.delete)
    }

    private func resolveUniqueChronometry(
        remoteID: Int64,
        context: NSManagedObjectContext
    ) throws -> ChronometryMO? {
        let request = ChronometryMO.fetchRequest()
        request.predicate = NSPredicate(format: "remoteID == %@", NSNumber(value: remoteID))

        let matches = try context.fetch(request)
        guard let primary = matches.first else { return nil }

        for duplicate in matches.dropFirst() {
            context.delete(duplicate)
        }

        return primary
    }
}
