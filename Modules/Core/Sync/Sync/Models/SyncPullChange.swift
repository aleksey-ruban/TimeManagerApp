import Foundation

public struct SyncPullChange: Sendable {
    public let stageID: SyncStageID
    public let payload: any Sendable

    public init(
        stageID: SyncStageID,
        payload: any Sendable
    ) {
        self.stageID = stageID
        self.payload = payload
    }
}
