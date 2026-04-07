import CoreSync
import Domain
import Foundation

final class ServerPullBatchSource: SyncPullBatchSourceProtocol, @unchecked Sendable {
    private let remoteAPI: SyncRemoteAPIServiceProtocol
    private let clientSnapshotVersion: SnapshotVersion
    private(set) var maxSnapshotVersion: SnapshotVersion

    init(
        remoteAPI: SyncRemoteAPIServiceProtocol,
        clientSnapshotVersion: SnapshotVersion
    ) {
        self.remoteAPI = remoteAPI
        self.clientSnapshotVersion = clientSnapshotVersion
        self.maxSnapshotVersion = clientSnapshotVersion
    }

    func fetchBatch(after cursor: String?) async throws -> SyncPullBatch? {
        guard let response = try await remoteAPI.fetchPullBatch(
            after: cursor,
            clientSnapshotVersion: clientSnapshotVersion
        ) else {
            return nil
        }

        maxSnapshotVersion = max(maxSnapshotVersion, response.maxSnapshotVersion)

        let changes =
            response.categories.map { SyncPullChange(stageID: CommonSyncStageIDs.categories, payload: $0) } +
            response.activities.map { SyncPullChange(stageID: CommonSyncStageIDs.activities, payload: $0) } +
            response.activityRecords.map { SyncPullChange(stageID: CommonSyncStageIDs.activityRecords, payload: $0) } +
            response.chronometries.map { SyncPullChange(stageID: CommonSyncStageIDs.chronometries, payload: $0) }

        if changes.isEmpty, response.nextCursor == nil, response.hasMore == false {
            return nil
        }

        return SyncPullBatch(
            changes: changes,
            nextCursor: response.nextCursor,
            hasMore: response.hasMore
        )
    }
}
