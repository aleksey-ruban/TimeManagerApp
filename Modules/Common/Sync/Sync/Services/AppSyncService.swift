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
        let startedAt = Date()
        let clientSnapshotVersion = await userProfileService.currentSnapshotVersion()
        let pullSource = ServerPullBatchSource(
            remoteAPI: remoteAPI,
            clientSnapshotVersion: clientSnapshotVersion
        )

        do {
            let pullResult = try await engine.run(
                trigger: trigger,
                pipeline: SyncPipeline(
                    pull: SyncPullConfiguration(
                        initialCursor: nil,
                        source: pullSource,
                        stages: pullStages
                    ),
                    pushStages: []
                )
            )

            await userProfileService.updateSnapshotVersion(pullSource.maxSnapshotVersion)

            let pushResult = try await engine.run(
                trigger: trigger,
                pipeline: SyncPipeline(pushStages: pushStages)
            )

            let result = SyncRunResult(
                trigger: trigger,
                startedAt: startedAt,
                finishedAt: Date(),
                stageResults: pullResult.stageResults + pushResult.stageResults,
                pullCursor: pullResult.pullCursor
            )

            NotificationCenter.default.post(name: .appSyncServiceDidFinishRun, object: nil)
            return result
        } catch {
            NotificationCenter.default.post(name: .appSyncServiceDidFinishRun, object: nil)
            throw error
        }
    }
}
