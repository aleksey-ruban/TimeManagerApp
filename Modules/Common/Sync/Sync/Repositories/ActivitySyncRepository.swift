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
                let existing = try self.resolveUniqueActivity(remoteID: remote.id, context: context)
                let localVersion = existing?.lastModifiedVersionValue ?? .min

                if let existing, remote.lastModifiedVersion <= localVersion {
                    if remote.lastModifiedVersion == localVersion {
                        self.hydrateMissingVariationRemoteIDs(
                            on: existing,
                            with: remote.variations
                        )
                    }
                    continue
                }

                // Preserve a local tombstone so the delete can still be pushed to the server.
                if let existing, existing.isDirty, existing.syncDeleted {
                    existing.remoteID = NSNumber(value: remote.id)
                    existing.lastModifiedVersion = NSNumber(value: remote.lastModifiedVersion)
                    applied += 1
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
                object.lastModifiedVersion = ack.lastModifiedVersion.map(NSNumber.init(value:))
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
        let current = (activity.variations ?? []).sorted { lhs, rhs in
            let lhsRemoteID = lhs.remoteIDValue ?? .min
            let rhsRemoteID = rhs.remoteIDValue ?? .min

            if lhsRemoteID != rhsRemoteID {
                return lhsRemoteID < rhsRemoteID
            }

            if lhs.position != rhs.position {
                return lhs.position < rhs.position
            }

            return lhs.localID.uuidString < rhs.localID.uuidString
        }
        var existingByRemoteID: [Int64: ActivityVariationMO] = [:]
        var localOnlyVariations: [ActivityVariationMO] = []

        for variation in current {
            if let remoteID = variation.remoteIDValue {
                if let primary = existingByRemoteID[remoteID] {
                    reattachRecords(from: variation, to: primary)
                    context.delete(variation)
                } else {
                    existingByRemoteID[remoteID] = variation
                }
            } else {
                localOnlyVariations.append(variation)
            }
        }

        var updatedVariations: [ActivityVariationMO] = []
        var reusedLocalOnlyIndices = Set<Int>()

        for remote in remoteVariations {
            let variation: ActivityVariationMO

            if let remoteID = remote.id, let existing = existingByRemoteID.removeValue(forKey: remoteID) {
                variation = existing
            } else if let fallbackIndex = localOnlyVariations.indices.first(where: { reusedLocalOnlyIndices.contains($0) == false }) {
                variation = localOnlyVariations[fallbackIndex]
                reusedLocalOnlyIndices.insert(fallbackIndex)
            } else {
                variation = ActivityVariationMO(context: context)
                variation.localID = UUID()
            }

            variation.remoteID = remote.id.map(NSNumber.init(value:))
            variation.value = remote.value
            variation.position = Int64(remote.position)
            variation.syncDeleted = remote.deleted
            variation.activity = activity
            updatedVariations.append(variation)
        }

        for stale in existingByRemoteID.values {
            context.delete(stale)
        }

        for (index, localOnlyVariation) in localOnlyVariations.enumerated() where reusedLocalOnlyIndices.contains(index) == false {
            context.delete(localOnlyVariation)
        }

        activity.variations = Set(updatedVariations)
    }

    private func hydrateMissingVariationRemoteIDs(
        on activity: ActivityMO,
        with remoteVariations: [RemoteVariationDTO]
    ) {
        guard let variations = activity.variations, variations.isEmpty == false else { return }

        var localWithoutRemoteID = variations.filter { $0.remoteIDValue == nil }
        guard localWithoutRemoteID.isEmpty == false else { return }

        var assignedRemoteIDs = Set(variations.compactMap(\.remoteIDValue))

        for remote in remoteVariations {
            guard let remoteID = remote.id, assignedRemoteIDs.contains(remoteID) == false else { continue }

            let exactMatches = localWithoutRemoteID.filter {
                $0.value == remote.value &&
                $0.syncDeleted == remote.deleted &&
                Int($0.position) == remote.position
            }
            if exactMatches.count == 1, let match = exactMatches.first {
                match.remoteID = NSNumber(value: remoteID)
                assignedRemoteIDs.insert(remoteID)
                localWithoutRemoteID = localWithoutRemoteID.filter { $0.localID != match.localID }
                continue
            }

            let valueMatches = localWithoutRemoteID.filter {
                $0.value == remote.value &&
                $0.syncDeleted == remote.deleted
            }
            if valueMatches.count == 1, let match = valueMatches.first {
                match.remoteID = NSNumber(value: remoteID)
                assignedRemoteIDs.insert(remoteID)
                localWithoutRemoteID = localWithoutRemoteID.filter { $0.localID != match.localID }
                continue
            }

            let positionMatches = localWithoutRemoteID.filter {
                $0.syncDeleted == remote.deleted &&
                Int($0.position) == remote.position
            }
            if positionMatches.count == 1, let match = positionMatches.first {
                match.remoteID = NSNumber(value: remoteID)
                assignedRemoteIDs.insert(remoteID)
                localWithoutRemoteID = localWithoutRemoteID.filter { $0.localID != match.localID }
            }
        }
    }

    private func resolveUniqueActivity(
        remoteID: Int64,
        context: NSManagedObjectContext
    ) throws -> ActivityMO? {
        let request = ActivityMO.fetchRequest()
        request.predicate = NSPredicate(format: "remoteID == %@", NSNumber(value: remoteID))

        let matches = try context.fetch(request)
        guard let primary = matches.first else { return nil }

        for duplicate in matches.dropFirst() {
            context.delete(duplicate)
        }

        return primary
    }

    private func reattachRecords(
        from duplicate: ActivityVariationMO,
        to primary: ActivityVariationMO
    ) {
        (duplicate.records ?? []).forEach { $0.variation = primary }
    }
}
