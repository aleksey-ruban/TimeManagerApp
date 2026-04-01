import Foundation

public protocol SyncPushStageProtocol: Sendable {
    var id: SyncStageID { get }

    func execute(context: SyncExecutionContext) async throws -> Int
}
