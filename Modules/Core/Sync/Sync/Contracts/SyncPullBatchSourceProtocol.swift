import Foundation

public protocol SyncPullBatchSourceProtocol: Sendable {
    func fetchBatch(after cursor: String?) async throws -> SyncPullBatch?
}
