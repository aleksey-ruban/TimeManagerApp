import Foundation

public struct SyncPipeline: Sendable {
    public let pull: SyncPullConfiguration?
    public let pushStages: [any SyncPushStageProtocol]

    public init(
        pull: SyncPullConfiguration? = nil,
        pushStages: [any SyncPushStageProtocol]
    ) {
        self.pull = pull
        self.pushStages = pushStages
    }
}
