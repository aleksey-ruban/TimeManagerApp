import CommonUserProfile
import CoreSync
import Domain
import Foundation

public final class AppSyncService: AppSyncServiceProtocol, @unchecked Sendable {
    private let engine: SyncEngineProtocol
    private let remoteAPI: SyncRemoteAPIServiceProtocol
    private let userProfileService: UserProfileServiceProtocol
    private let pullStages: [any SyncPullStageProtocol]
    private let pushStages: [any SyncPushStageProtocol]

    init(
        engine: SyncEngineProtocol,
        remoteAPI: SyncRemoteAPIServiceProtocol,
        userProfileService: UserProfileServiceProtocol,
        pullStages: [any SyncPullStageProtocol],
        pushStages: [any SyncPushStageProtocol]
    ) {
        self.engine = engine
        self.remoteAPI = remoteAPI
        self.userProfileService = userProfileService
        self.pullStages = pullStages
        self.pushStages = pushStages
    }

    public func run(trigger: SyncTrigger) async throws -> SyncRunResult {
        let clientSnapshotVersion = await userProfileService.currentSnapshotVersion()
        let pullSource = ServerPullBatchSource(
            remoteAPI: remoteAPI,
            clientSnapshotVersion: clientSnapshotVersion
        )

        let pipeline = SyncPipeline(
            pull: SyncPullConfiguration(
                initialCursor: nil,
                source: pullSource,
                stages: pullStages
            ),
            pushStages: pushStages
        )

        do {
            let result = try await engine.run(
                trigger: trigger,
                pipeline: pipeline
            )

            await userProfileService.updateSnapshotVersion(pullSource.maxSnapshotVersion)
            NotificationCenter.default.post(name: .appSyncServiceDidFinishRun, object: nil)
            return result
        } catch {
            NotificationCenter.default.post(name: .appSyncServiceDidFinishRun, object: nil)
            throw error
        }
    }
}
