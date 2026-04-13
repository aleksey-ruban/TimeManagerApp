import CoreSync
import Foundation

final class ActivitiesPushStage: SyncPushStageProtocol, @unchecked Sendable {
    let id: SyncStageID = CommonSyncStageIDs.activities

    private let repository: ActivitySyncRepository
    private let remoteAPI: SyncRemoteAPIServiceProtocol

    init(
        repository: ActivitySyncRepository,
        remoteAPI: SyncRemoteAPIServiceProtocol
    ) {
        self.repository = repository
        self.remoteAPI = remoteAPI
    }

    func execute(context: SyncExecutionContext) async throws -> Int {
        let dirty = try await repository.fetchDirty()
        guard dirty.isEmpty == false else { return 0 }

        let response = try await remoteAPI.pushActivities(dirty)
        guard response.count == dirty.count else {
            throw CommonSyncError.responseCountMismatch(
                stage: id.rawValue,
                expected: dirty.count,
                received: response.count
            )
        }

        let acknowledgements = try response.map { result in
            guard result.status?.uppercased() != "ERROR" else {
                throw CommonSyncError.pushRejected(
                    stage: id.rawValue,
                    localID: result.localId,
                    status: result.status,
                    errorCode: result.errorCode,
                    errorMessage: result.errorMessage
                )
            }
            return ActivityPushAcknowledgement(
                localID: result.localId,
                remoteID: result.serverId,
                lastModifiedVersion: result.lastModifiedVersion
            )
        }

        return try await repository.acknowledgePush(acknowledgements)
    }
}
