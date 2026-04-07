import XCTest
@testable import CoreSync

final class SyncEngineTests: XCTestCase {
    func testRunAccumulatesAllPullBatchesAndAppliesThemByTypeOrder() async throws {
        let reachabilityMonitor = ReachabilityMonitorMock(isReachable: true)
        let recorder = StageRecorder()
        let engine = SyncAssembly(
            reachabilityMonitor: reachabilityMonitor
        ).makeEngine()

        let source = PullBatchSourceStub(
            batches: [
                SyncPullBatch(
                    changes: [
                        SyncPullChange(stageID: "categories", payload: "c1"),
                        SyncPullChange(stageID: "tasks", payload: "t1"),
                    ],
                    nextCursor: "cursor-1",
                    hasMore: true
                ),
                SyncPullBatch(
                    changes: [
                        SyncPullChange(stageID: "categories", payload: "c2"),
                        SyncPullChange(stageID: "taskRecords", payload: "r1"),
                    ],
                    nextCursor: nil,
                    hasMore: false
                ),
            ]
        )

        let pipeline = SyncPipeline(
            pull: SyncPullConfiguration(
                initialCursor: "cursor-0",
                source: source,
                stages: [
                    PullStageSpy(id: "categories", recorder: recorder, payloadExtractor: Self.stringPayloads),
                    PullStageSpy(id: "tasks", recorder: recorder, payloadExtractor: Self.stringPayloads),
                    PullStageSpy(id: "taskRecords", recorder: recorder, payloadExtractor: Self.stringPayloads),
                ]
            ),
            pushStages: [
                PushStageSpy(id: "categories", recorder: recorder, dirtyObjects: ["local-category"]),
                PushStageSpy(id: "tasks", recorder: recorder, dirtyObjects: ["local-task-1", "local-task-2"]),
            ]
        )

        let result = try await engine.run(trigger: .manual, pipeline: pipeline)

        let events = await recorder.allEvents()
        XCTAssertEqual(
            events,
            [
                "categories:pull:c1,c2",
                "tasks:pull:t1",
                "taskRecords:pull:r1",
                "categories:push:local-category",
                "tasks:push:local-task-1,local-task-2",
            ]
        )
        XCTAssertEqual(
            result.stageResults.map(\.stageID.rawValue),
            ["categories", "tasks", "taskRecords", "categories", "tasks"]
        )
        XCTAssertEqual(result.stageResults.map(\.processedItemsCount), [2, 1, 1, 1, 2])

        let requestedCursors = await source.cursors()
        XCTAssertEqual(requestedCursors, ["cursor-0", "cursor-1"])
        XCTAssertNil(result.pullCursor)
    }

    func testRunStopsAfterProcessingFinalNonEmptyPullBatch() async throws {
        let engine = SyncAssembly(
            reachabilityMonitor: ReachabilityMonitorMock(isReachable: true)
        ).makeEngine()
        let source = PullBatchSourceStub(
            batches: [
                SyncPullBatch(
                    changes: [SyncPullChange(stageID: "categories", payload: "c1")],
                    nextCursor: nil,
                    hasMore: false
                )
            ]
        )

        let pipeline = SyncPipeline(
            pull: SyncPullConfiguration(
                initialCursor: nil,
                source: source,
                stages: [
                    PullStageSpy(id: "categories", recorder: StageRecorder(), payloadExtractor: Self.stringPayloads),
                ]
            ),
            pushStages: []
        )

        let result = try await engine.run(trigger: .manual, pipeline: pipeline)

        let requestedCursors = await source.cursors()
        XCTAssertEqual(requestedCursors, [nil])
        XCTAssertEqual(result.stageResults.first?.processedItemsCount, 1)
        XCTAssertNil(result.pullCursor)
    }

    func testEachPushStageOwnsItsDirtySelectionWithoutGlobalScanner() async throws {
        let recorder = StageRecorder()
        let engine = SyncAssembly(
            reachabilityMonitor: ReachabilityMonitorMock(isReachable: true)
        ).makeEngine()

        let pipeline = SyncPipeline(
            pushStages: [
                PushStageSpy(id: "categories", recorder: recorder, dirtyObjects: ["c-local-1"]),
                PushStageSpy(id: "tasks", recorder: recorder, dirtyObjects: ["t-local-1", "t-local-2"]),
                PushStageSpy(id: "taskRecords", recorder: recorder, dirtyObjects: []),
            ]
        )

        let result = try await engine.run(trigger: .localChange, pipeline: pipeline)

        let pushEvents = await recorder.allEvents()
        XCTAssertEqual(
            pushEvents,
            [
                "categories:push:c-local-1",
                "tasks:push:t-local-1,t-local-2",
                "taskRecords:push:",
            ]
        )
        XCTAssertEqual(result.stageResults.map(\.processedItemsCount), [1, 2, 0])
    }

    func testAssemblyCreatesEngineThatFailsWhenNetworkIsUnavailable() async throws {
        let engine = SyncAssembly(
            reachabilityMonitor: ReachabilityMonitorMock(isReachable: false)
        ).makeEngine()

        do {
            _ = try await engine.run(trigger: .manual, pipeline: SyncPipeline(pushStages: []))
            XCTFail("Expected networkUnavailable")
        } catch let error as SyncEngineError {
            XCTAssertEqual(error, .networkUnavailable)
        }
    }

    private static func stringPayloads(from changes: [SyncPullChange]) -> [String] {
        changes.compactMap { $0.payload as? String }
    }
}
