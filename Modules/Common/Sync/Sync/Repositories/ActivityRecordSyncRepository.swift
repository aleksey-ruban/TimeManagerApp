import CoreData
import CoreStorage
import Domain
import Foundation

final class ActivityRecordSyncRepository: @unchecked Sendable {
    private let coreDataStack: CoreDataStackProtocol

    init(coreDataStack: CoreDataStackProtocol) {
        self.coreDataStack = coreDataStack
    }

    func fetchDirty() async throws -> [ActivityRecord] {
        try await coreDataStack.performBackgroundTask { context in
            let request = ActivityRecordMO.fetchRequest()
            request.predicate = NSPredicate(
                format: "isDirty == YES AND activity.remoteID != nil"
            )
            request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: true)]
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func applyRemote(_ records: [RemoteActivityRecordDTO]) async throws -> Int {
        try await coreDataStack.performBackgroundTransaction { [self] context in
            var applied = 0

            for remote in records {
                let existing = try self.resolveUniqueActivityRecord(remoteID: remote.id, context: context)
                let localVersion = existing?.lastModifiedVersionValue ?? .min

                if existing != nil, remote.lastModifiedVersion <= localVersion {
                    continue
                }

                guard let activity = try self.resolveActivity(remote.activityId, context: context) else {
                    continue
                }

                let object = existing ?? ActivityRecordMO(context: context)
                if existing == nil {
                    object.localID = UUID()
                }

                object.remoteID = NSNumber(value: remote.id)
                object.lastModifiedVersion = NSNumber(value: remote.lastModifiedVersion)
                object.activity = activity
                object.variation = try self.resolveVariation(remote.variationId, context: context)
                object.startedAt = remote.startedAt
                object.endedAt = remote.endedAt
                object.timeZone = remote.timeZone
                object.syncDeleted = remote.deleted
                object.isDirty = false
                applied += 1
            }

            return applied
        }
    }

    func acknowledgePush(_ acknowledgements: [ActivityRecordPushAcknowledgement]) async throws -> Int {
        try await coreDataStack.performBackgroundTransaction { context in
            var updated = 0

            for ack in acknowledgements {
                let request = ActivityRecordMO.fetchRequest()
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

    private func resolveActivity(
        _ remoteID: Int64,
        context: NSManagedObjectContext
    ) throws -> ActivityMO? {
        let request = ActivityMO.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "remoteID == %@", NSNumber(value: remoteID))
        return try context.fetch(request).first
    }

    private func resolveVariation(
        _ remoteID: Int64?,
        context: NSManagedObjectContext
    ) throws -> ActivityVariationMO? {
        guard let remoteID else { return nil }
        let request = ActivityVariationMO.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "remoteID == %@", NSNumber(value: remoteID))
        return try context.fetch(request).first
    }

    private func resolveUniqueActivityRecord(
        remoteID: Int64,
        context: NSManagedObjectContext
    ) throws -> ActivityRecordMO? {
        let request = ActivityRecordMO.fetchRequest()
        request.predicate = NSPredicate(format: "remoteID == %@", NSNumber(value: remoteID))

        let matches = try context.fetch(request)
        guard let primary = matches.first else { return nil }

        for duplicate in matches.dropFirst() {
            context.delete(duplicate)
        }

        return primary
    }
}
