import Foundation

public struct SyncPullConfiguration: Sendable {
    public let initialCursor: String?
    public let source: any SyncPullBatchSourceProtocol
    public let stages: [any SyncPullStageProtocol]

    public init(
        initialCursor: String? = nil,
        source: any SyncPullBatchSourceProtocol,
        stages: [any SyncPullStageProtocol]
    ) {
        self.initialCursor = initialCursor
        self.source = source
        self.stages = stages
    }
}
