import CoreSync
import Foundation

final class ActivitiesPullStage: SyncPullStageProtocol, @unchecked Sendable {
    let id: SyncStageID = CommonSyncStageIDs.activities

    private let repository: ActivitySyncRepository

    init(repository: ActivitySyncRepository) {
        self.repository = repository
    }

    func apply(
        changes: [SyncPullChange],
        context: SyncExecutionContext
    ) async throws -> Int {
        let payload = try changes.map { change -> RemoteActivityDTO in
            guard let value = change.payload as? RemoteActivityDTO else {
                throw CommonSyncError.unsupportedPayload(stage: id.rawValue)
            }
            return value
        }

        return try await repository.applyRemote(payload)
    }
}
