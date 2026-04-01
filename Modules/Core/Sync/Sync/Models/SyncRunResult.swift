import Foundation

public struct SyncRunResult: Sendable, Equatable {
    public let trigger: SyncTrigger
    public let startedAt: Date
    public let finishedAt: Date
    public let stageResults: [SyncStageResult]
    public let pullCursor: String?

    public init(
        trigger: SyncTrigger,
        startedAt: Date,
        finishedAt: Date,
        stageResults: [SyncStageResult],
        pullCursor: String? = nil
    ) {
        self.trigger = trigger
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.stageResults = stageResults
        self.pullCursor = pullCursor
    }
}
