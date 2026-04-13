import Foundation
@testable import CoreSync

final class ReachabilityMonitorMock: ReachabilityMonitorProtocol {
    let isReachable: Bool

    init(isReachable: Bool) {
        self.isReachable = isReachable
    }
}

actor PullBatchSourceStub: SyncPullBatchSourceProtocol {
    private var remainingBatches: [SyncPullBatch]
    private(set) var receivedCursors: [String?] = []

    init(batches: [SyncPullBatch]) {
        remainingBatches = batches
    }

    func fetchBatch(after cursor: String?) async throws -> SyncPullBatch? {
        receivedCursors.append(cursor)
        guard !remainingBatches.isEmpty else {
            return nil
        }

        return remainingBatches.removeFirst()
    }

    func cursors() -> [String?] {
        receivedCursors
    }
}

struct PullStageSpy: SyncPullStageProtocol {
    let id: SyncStageID
    let recorder: StageRecorder
    let payloadExtractor: @Sendable ([SyncPullChange]) -> [String]

    func apply(
        changes: [SyncPullChange],
        context: SyncExecutionContext
    ) async throws -> Int {
        let values = payloadExtractor(changes)
        await recorder.record("\(id.rawValue):pull:\(values.joined(separator: ","))")
        return values.count
    }
}

struct PushStageSpy: SyncPushStageProtocol {
    let id: SyncStageID
    let recorder: StageRecorder
    let dirtyObjects: [String]

    func execute(context: SyncExecutionContext) async throws -> Int {
        await recorder.record("\(id.rawValue):push:\(dirtyObjects.joined(separator: ","))")
        return dirtyObjects.count
    }
}

actor StageRecorder {
    private(set) var events: [String] = []

    func record(_ value: String) {
        events.append(value)
    }

    func allEvents() -> [String] {
        events
    }
}
