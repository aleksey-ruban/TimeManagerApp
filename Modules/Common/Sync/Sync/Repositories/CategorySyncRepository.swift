import CoreData
import CoreStorage
import Domain
import Foundation

final class CategorySyncRepository: @unchecked Sendable {
    private let coreDataStack: CoreDataStackProtocol

    init(coreDataStack: CoreDataStackProtocol) {
        self.coreDataStack = coreDataStack
    }

    func fetchDirty() async throws -> [Domain.Category] {
        try await coreDataStack.performBackgroundTask { context in
            let request = CategoryMO.fetchRequest()
            request.predicate = NSPredicate(format: "isDirty == YES")
            request.sortDescriptors = [NSSortDescriptor(key: "baseName", ascending: true)]
            return try context.fetch(request).map { $0.toDTO() }
        }
    }

    func applyRemote(_ categories: [RemoteCategoryDTO]) async throws -> Int {
        try await coreDataStack.performBackgroundTransaction { context in
            var applied = 0

            for remote in categories {
                let request = CategoryMO.fetchRequest()
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "remoteID == %@", NSNumber(value: remote.id))

                let existing = try context.fetch(request).first
                let localVersion = existing?.lastModifiedVersionValue ?? .min

                if existing != nil, remote.lastModifiedVersion <= localVersion {
                    continue
                }

                let object = existing ?? CategoryMO(context: context)
                object.remoteID = NSNumber(value: remote.id)
                object.lastModifiedVersion = NSNumber(value: remote.lastModifiedVersion)
                object.baseName = remote.name
                object.code = remote.code
                object.syncDeleted = remote.deleted
                object.isDirty = false

                if existing == nil {
                    object.localID = UUID()
                }

                applied += 1
            }

            return applied
        }
    }

    func acknowledgePush(_ acknowledgements: [CategoryPushAcknowledgement]) async throws -> Int {
        try await coreDataStack.performBackgroundTransaction { context in
            var updated = 0

            for ack in acknowledgements {
                let request = CategoryMO.fetchRequest()
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
}
