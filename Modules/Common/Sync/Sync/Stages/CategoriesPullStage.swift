import CoreSync
import Foundation

final class CategoriesPullStage: SyncPullStageProtocol, @unchecked Sendable {
    let id: SyncStageID = CommonSyncStageIDs.categories

    private let repository: CategorySyncRepository

    init(repository: CategorySyncRepository) {
        self.repository = repository
    }

    func apply(
        changes: [SyncPullChange],
        context: SyncExecutionContext
    ) async throws -> Int {
        let payload = try changes.map { change -> RemoteCategoryDTO in
            guard let value = change.payload as? RemoteCategoryDTO else {
                throw CommonSyncError.unsupportedPayload(stage: id.rawValue)
            }
            return value
        }

        return try await repository.applyRemote(payload)
    }
}
