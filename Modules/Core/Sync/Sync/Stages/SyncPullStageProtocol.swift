import Foundation

public protocol SyncPullStageProtocol: Sendable {
    var id: SyncStageID { get }

    func apply(
        changes: [SyncPullChange],
        context: SyncExecutionContext
    ) async throws -> Int
}
