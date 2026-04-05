import CoreSync
import Foundation

final class ActivityRecordsPullStage: SyncPullStageProtocol, @unchecked Sendable {
    let id: SyncStageID = CommonSyncStageIDs.activityRecords

    private let repository: ActivityRecordSyncRepository

    init(repository: ActivityRecordSyncRepository) {
        self.repository = repository
    }

    func apply(
        changes: [SyncPullChange],
        context: SyncExecutionContext
    ) async throws -> Int {
        let payload = try changes.map { change -> RemoteActivityRecordDTO in
            guard let value = change.payload as? RemoteActivityRecordDTO else {
                throw CommonSyncError.unsupportedPayload(stage: id.rawValue)
            }
            return value
        }

        return try await repository.applyRemote(payload)
    }
}
