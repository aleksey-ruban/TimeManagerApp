import Foundation

public protocol SyncEngineProtocol: Sendable {
    func run(
        trigger: SyncTrigger,
        pipeline: SyncPipeline
    ) async throws -> SyncRunResult
}
