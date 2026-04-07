import Foundation

public struct SyncPullBatch: Sendable {
    public let changes: [SyncPullChange]
    public let nextCursor: String?
    public let hasMore: Bool

    public init(
        changes: [SyncPullChange],
        nextCursor: String?,
        hasMore: Bool
    ) {
        self.changes = changes
        self.nextCursor = nextCursor
        self.hasMore = hasMore
    }
}
