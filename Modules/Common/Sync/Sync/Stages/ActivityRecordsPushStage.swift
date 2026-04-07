import CoreSync
import Foundation

final class ActivityRecordsPushStage: SyncPushStageProtocol, @unchecked Sendable {
    let id: SyncStageID = CommonSyncStageIDs.activityRecords

    private let repository: ActivityRecordSyncRepository
    private let remoteAPI: SyncRemoteAPIServiceProtocol

    init(
        repository: ActivityRecordSyncRepository,
        remoteAPI: SyncRemoteAPIServiceProtocol
    ) {
        self.repository = repository
        self.remoteAPI = remoteAPI
    }

    func execute(context: SyncExecutionContext) async throws -> Int {
        let dirty = try await repository.fetchDirty()
        guard dirty.isEmpty == false else { return 0 }

        let response = try await remoteAPI.pushActivityRecords(dirty)
        guard response.count == dirty.count else {
            throw CommonSyncError.responseCountMismatch(
                stage: id.rawValue,
                expected: dirty.count,
                received: response.count
            )
        }

        let acknowledgements = try response.map { result in
            guard result.status?.uppercased() != "ERROR" else {
                throw CommonSyncError.pushRejected(stage: id.rawValue, localID: result.localId, status: result.status)
            }
            return ActivityRecordPushAcknowledgement(
                localID: result.localId,
                remoteID: result.serverId,
                lastModifiedVersion: result.lastModifiedVersion
            )
        }

        return try await repository.acknowledgePush(acknowledgements)
    }
}
