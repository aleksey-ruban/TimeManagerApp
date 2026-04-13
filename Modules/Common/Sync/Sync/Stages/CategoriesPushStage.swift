import CoreSync
import Foundation

final class CategoriesPushStage: SyncPushStageProtocol, @unchecked Sendable {
    let id: SyncStageID = CommonSyncStageIDs.categories

    private let repository: CategorySyncRepository
    private let remoteAPI: SyncRemoteAPIServiceProtocol

    init(
        repository: CategorySyncRepository,
        remoteAPI: SyncRemoteAPIServiceProtocol
    ) {
        self.repository = repository
        self.remoteAPI = remoteAPI
    }

    func execute(context: SyncExecutionContext) async throws -> Int {
        let dirty = try await repository.fetchDirty()
        guard dirty.isEmpty == false else { return 0 }

        let response = try await remoteAPI.pushCategories(dirty)
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
            return CategoryPushAcknowledgement(
                localID: result.localId,
                remoteID: result.serverId,
                lastModifiedVersion: result.lastModifiedVersion
            )
        }

        return try await repository.acknowledgePush(acknowledgements)
    }
}
