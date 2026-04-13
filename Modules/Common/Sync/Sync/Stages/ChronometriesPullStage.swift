import CoreSync
import Foundation

final class ChronometriesPullStage: SyncPullStageProtocol, @unchecked Sendable {
    let id: SyncStageID = CommonSyncStageIDs.chronometries

    private let repository: ChronometrySyncRepository

    init(repository: ChronometrySyncRepository) {
        self.repository = repository
    }

    func apply(
        changes: [SyncPullChange],
        context: SyncExecutionContext
    ) async throws -> Int {
        let payload = try changes.map { change -> RemoteChronometryDTO in
            guard let value = change.payload as? RemoteChronometryDTO else {
                throw CommonSyncError.unsupportedPayload(stage: id.rawValue)
            }
            return value
        }

        return try await repository.applyRemote(payload)
    }
}
