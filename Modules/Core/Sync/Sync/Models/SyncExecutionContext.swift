import Foundation

public struct SyncExecutionContext: Sendable {
    public let trigger: SyncTrigger
    public let startedAt: Date

    public init(
        trigger: SyncTrigger,
        startedAt: Date
    ) {
        self.trigger = trigger
        self.startedAt = startedAt
    }
}
