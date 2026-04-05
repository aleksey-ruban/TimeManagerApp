import CoreData
import CoreStorage
import Domain
import Foundation

final class ActivitySyncRepository: @unchecked Sendable {
    private let coreDataStack: CoreDataStackProtocol

    init(coreDataStack: CoreDataStackProtocol) {
        self.coreDataStack = coreDataStack
    }

    func fetchDirty() async throws -> [Activity] {
        try await coreDataStack.performBackgroundTask { context in
            let request = ActivityMO.fetchRequest()
            request.predicate = NSPredicate(
                format: "isDirty == YES AND (category == nil OR category.remoteID != nil)"
            )
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func applyRemote(_ activities: [RemoteActivityDTO]) async throws -> Int {
        try await coreDataStack.performBackgroundTransaction { [self] context in
            var applied = 0

            for remote in activities {
                let request = ActivityMO.fetchRequest()
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "remoteID == %@", NSNumber(value: remote.id))

                let existing = try context.fetch(request).first
                let localVersion = existing?.lastModifiedVersionValue ?? .min

                if existing != nil, remote.lastModifiedVersion <= localVersion {
                    continue
                }

                let object = existing ?? ActivityMO(context: context)
                if existing == nil {
                    object.localID = UUID()
                }

                object.remoteID = NSNumber(value: remote.id)
                object.lastModifiedVersion = NSNumber(value: remote.lastModifiedVersion)
                object.name = remote.name
                object.iconName = remote.icon
                object.colorRawValue = remote.iconColor
                object.syncDeleted = remote.deleted
                object.isDirty = false
                object.category = try self.resolveCategory(remote.categoryId, context: context)

                self.replaceVariations(
                    on: object,
                    with: remote.variations,
                    context: context
                )

                applied += 1
            }

            return applied
        }
    }

    func acknowledgePush(_ acknowledgements: [ActivityPushAcknowledgement]) async throws -> Int {
        try await coreDataStack.performBackgroundTransaction { context in
            var updated = 0

            for ack in acknowledgements {
                let request = ActivityMO.fetchRequest()
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "localID == %@", ack.localID as CVarArg)

                guard let object = try context.fetch(request).first else { continue }

                object.remoteID = ack.remoteID.map(NSNumber.init(value:))
                object.isDirty = false
                updated += 1
            }

            return updated
        }
    }

    private func resolveCategory(
        _ remoteID: Int64?,
        context: NSManagedObjectContext
    ) throws -> CategoryMO? {
        guard let remoteID else { return nil }
        let request = CategoryMO.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "remoteID == %@", NSNumber(value: remoteID))
        return try context.fetch(request).first
    }

    private func replaceVariations(
        on activity: ActivityMO,
        with remoteVariations: [RemoteVariationDTO],
        context: NSManagedObjectContext
    ) {
        let current = activity.variations ?? []
        for variation in current {
            context.delete(variation)
        }

        activity.variations = Set(remoteVariations.map { remote in
            let variation = ActivityVariationMO(context: context)
            variation.localID = UUID()
            variation.remoteID = remote.id.map(NSNumber.init(value:))
            variation.value = remote.value
            variation.position = Int64(remote.position)
            variation.syncDeleted = remote.deleted
            variation.activity = activity
            return variation
        })
    }
}
