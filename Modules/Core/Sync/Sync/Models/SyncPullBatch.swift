import Foundation

public struct SyncPullBatch: Sendable {
    public let changes: [SyncPullChange]
    public let nextCursor: String?

    public init(
        changes: [SyncPullChange],
        nextCursor: String?
    ) {
        self.changes = changes
        self.nextCursor = nextCursor
    }
}
