import CoreSync
import CoreUserProfile
import Foundation

final class ChronometriesPushStage: SyncPushStageProtocol, @unchecked Sendable {
    let id: SyncStageID = CommonSyncStageIDs.chronometries

    private let repository: ChronometrySyncRepository
    private let remoteAPI: SyncRemoteAPIServiceProtocol
    private let userProfileService: UserProfileServiceProtocol

    init(
        repository: ChronometrySyncRepository,
        remoteAPI: SyncRemoteAPIServiceProtocol,
        userProfileService: UserProfileServiceProtocol
    ) {
        self.repository = repository
        self.remoteAPI = remoteAPI
        self.userProfileService = userProfileService
    }

    func execute(context: SyncExecutionContext) async throws -> Int {
        let dirty = try await repository.fetchDirty()
        guard dirty.isEmpty == false else { return 0 }
        let accountSnapshotVersion = await userProfileService.currentSnapshotVersion()

        let response = try await remoteAPI.pushChronometries(
            dirty,
            accountSnapshotVersion: accountSnapshotVersion
        )
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
            return ChronometryPushAcknowledgement(
                localID: result.localId,
                remoteID: result.serverId,
                lastModifiedVersion: result.lastModifiedVersion
            )
        }

        return try await repository.acknowledgePush(acknowledgements)
    }
}
