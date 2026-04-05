import Domain

protocol SyncRemoteAPIServiceProtocol: Sendable {
    func fetchPullBatch(after cursor: String?, clientSnapshotVersion: SnapshotVersion) async throws -> SyncPullBatchResponseDTO?
    func pushCategories(_ categories: [Domain.Category]) async throws -> [SyncPushResultDTO]
    func pushActivities(_ activities: [Domain.Activity]) async throws -> [SyncPushResultDTO]
    func pushActivityRecords(_ records: [Domain.ActivityRecord]) async throws -> [SyncPushResultDTO]
    func pushChronometries(_ chronometries: [Domain.Chronometry]) async throws -> [SyncPushResultDTO]
}
