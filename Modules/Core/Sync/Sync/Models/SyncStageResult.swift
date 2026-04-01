import Foundation

public struct SyncStageResult: Sendable, Equatable {
    public let stageID: SyncStageID
    public let direction: SyncDirection
    public let startedAt: Date
    public let finishedAt: Date
    public let processedItemsCount: Int
    public let nextCursor: String?

    public init(
        stageID: SyncStageID,
        direction: SyncDirection,
        startedAt: Date,
        finishedAt: Date,
        processedItemsCount: Int,
        nextCursor: String? = nil
    ) {
        self.stageID = stageID
        self.direction = direction
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.processedItemsCount = processedItemsCount
        self.nextCursor = nextCursor
    }
}
