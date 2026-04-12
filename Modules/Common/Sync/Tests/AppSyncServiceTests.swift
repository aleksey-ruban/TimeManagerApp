import CommonUserProfile
import CoreSync
import Domain
import Foundation
import XCTest
@testable import CommonSync

final class AppSyncServiceTests: XCTestCase {
    func testRunUpdatesSnapshotVersionAfterPullBeforePushStages() async throws {
        let userProfileService = RecordingUserProfileService(snapshotVersion: SnapshotVersion(Int64(134)))
        let remoteAPI = SyncRemoteAPIStub(
            fetchPullBatchHandler: { _, clientSnapshotVersion in
                XCTAssertEqual(clientSnapshotVersion, SnapshotVersion(Int64(134)))

                let data = Data(
                    """
                    {
                      "message": "Data sent",
                      "data": {
                        "objects": [
                          {
                            "type": "ACTIVITY_RECORD",
                            "payload": {
                              "id": 440,
                              "lastModifiedVersion": 135,
                              "activityId": 108,
                              "variationId": null,
                              "startedAt": "2026-04-05T15:20:44Z",
                              "endedAt": "2026-04-05T17:20:44Z",
                              "timeZone": "Europe/Moscow",
                              "deleted": false
                            }
                          }
                        ],
                        "nextCursor": null,
                        "hasMore": false
                      }
                    }
                    """.utf8
                )

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(SyncPullBatchResponseDTO.self, from: data)
            }
        )

        let pushStage = SnapshotVersionAssertingPushStage(userProfileService: userProfileService)
        let service = AppSyncService(
            engine: TestSyncEngine(),
            remoteAPI: remoteAPI,
            userProfileService: userProfileService,
            pullStages: [NoopPullStage()],
            pushStages: [pushStage]
        )

        let result = try await service.run(trigger: .manual)

        XCTAssertEqual(result.stageResults.count, 1)
        XCTAssertEqual(result.stageResults.first?.direction, .push)
        XCTAssertEqual(await userProfileService.currentSnapshotVersion(), SnapshotVersion(Int64(135)))
        XCTAssertEqual(await pushStage.observedSnapshotVersion, SnapshotVersion(Int64(135)))
    }
}

private actor RecordingUserProfileService: UserProfileServiceProtocol {
    private var snapshotVersion: SnapshotVersion

    init(snapshotVersion: SnapshotVersion) {
        self.snapshotVersion = snapshotVersion
    }

    func fetchUser() async throws -> User {
        User(firstName: nil, email: nil, snapshotVersion: snapshotVersion)
    }

    func fetchSessions() async throws -> UserSessions {
        UserSessions(currentSessionID: 0, sessions: [])
    }

    func currentSnapshotVersion() async -> SnapshotVersion {
        snapshotVersion
    }

    func updateSnapshotVersion(_ snapshotVersion: SnapshotVersion) async {
        self.snapshotVersion = snapshotVersion
    }

    func clearUser() async {}

    func clearSessions() async {}
}

private actor TestSyncEngine: SyncEngineProtocol {
    private var runCount = 0

    func run(trigger: SyncTrigger, pipeline: SyncPipeline) async throws -> SyncRunResult {
        runCount += 1
        let startedAt = Date()

        if runCount == 1 {
            if let pull = pipeline.pull {
                _ = try await pull.source.fetchBatch(after: pull.initialCursor)
            }

            return SyncRunResult(
                trigger: trigger,
                startedAt: startedAt,
                finishedAt: Date(),
                stageResults: [],
                pullCursor: nil
            )
        }

        var stageResults: [SyncStageResult] = []
        let context = SyncExecutionContext(trigger: trigger, startedAt: startedAt)
        for stage in pipeline.pushStages {
            let processedItemsCount = try await stage.execute(context: context)
            stageResults.append(
                SyncStageResult(
                    stageID: stage.id,
                    direction: .push,
                    startedAt: startedAt,
                    finishedAt: Date(),
                    processedItemsCount: processedItemsCount
                )
            )
        }

        return SyncRunResult(
            trigger: trigger,
            startedAt: startedAt,
            finishedAt: Date(),
            stageResults: stageResults,
            pullCursor: nil
        )
    }
}

private struct NoopPullStage: SyncPullStageProtocol {
    let id: SyncStageID = "noopPull"

    func apply(changes: [SyncPullChange], context: SyncExecutionContext) async throws -> Int {
        changes.count
    }
}

private actor SnapshotVersionAssertingPushStage: SyncPushStageProtocol {
    let id: SyncStageID = "snapshotProbe"
    private let userProfileService: UserProfileServiceProtocol
    private(set) var observedSnapshotVersion: SnapshotVersion?

    init(userProfileService: UserProfileServiceProtocol) {
        self.userProfileService = userProfileService
    }

    func execute(context: SyncExecutionContext) async throws -> Int {
        observedSnapshotVersion = await userProfileService.currentSnapshotVersion()
        return 1
    }
}
