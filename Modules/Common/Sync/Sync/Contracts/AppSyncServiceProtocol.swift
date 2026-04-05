import CoreSync

public protocol AppSyncServiceProtocol: Sendable {
    func run(trigger: SyncTrigger) async throws -> SyncRunResult
}
