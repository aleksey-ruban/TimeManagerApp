import CoreStorage
import Domain
import Foundation
@testable import CommonSync

actor SyncRemoteAPIStub: SyncRemoteAPIServiceProtocol {
    var fetchPullBatchHandler: @Sendable (String?, SnapshotVersion) async throws -> SyncPullBatchResponseDTO?
    var pushCategoriesHandler: @Sendable ([Domain.Category]) async throws -> [SyncPushResultDTO]
    var pushActivitiesHandler: @Sendable ([Domain.Activity]) async throws -> [SyncPushResultDTO]
    var pushActivityRecordsHandler: @Sendable ([Domain.ActivityRecord]) async throws -> [SyncPushResultDTO]
    var pushChronometriesHandler: @Sendable ([Domain.Chronometry]) async throws -> [SyncPushResultDTO]

    init(
        fetchPullBatchHandler: @escaping @Sendable (String?, SnapshotVersion) async throws -> SyncPullBatchResponseDTO? = { _, _ in nil },
        pushCategoriesHandler: @escaping @Sendable ([Domain.Category]) async throws -> [SyncPushResultDTO] = { _ in [] },
        pushActivitiesHandler: @escaping @Sendable ([Domain.Activity]) async throws -> [SyncPushResultDTO] = { _ in [] },
        pushActivityRecordsHandler: @escaping @Sendable ([Domain.ActivityRecord]) async throws -> [SyncPushResultDTO] = { _ in [] },
        pushChronometriesHandler: @escaping @Sendable ([Domain.Chronometry]) async throws -> [SyncPushResultDTO] = { _ in [] }
    ) {
        self.fetchPullBatchHandler = fetchPullBatchHandler
        self.pushCategoriesHandler = pushCategoriesHandler
        self.pushActivitiesHandler = pushActivitiesHandler
        self.pushActivityRecordsHandler = pushActivityRecordsHandler
        self.pushChronometriesHandler = pushChronometriesHandler
    }

    func fetchPullBatch(after cursor: String?, clientSnapshotVersion: SnapshotVersion) async throws -> SyncPullBatchResponseDTO? {
        try await fetchPullBatchHandler(cursor, clientSnapshotVersion)
    }

    func pushCategories(_ categories: [Domain.Category]) async throws -> [SyncPushResultDTO] {
        try await pushCategoriesHandler(categories)
    }

    func pushActivities(_ activities: [Domain.Activity]) async throws -> [SyncPushResultDTO] {
        try await pushActivitiesHandler(activities)
    }

    func pushActivityRecords(_ records: [Domain.ActivityRecord]) async throws -> [SyncPushResultDTO] {
        try await pushActivityRecordsHandler(records)
    }

    func pushChronometries(_ chronometries: [Domain.Chronometry]) async throws -> [SyncPushResultDTO] {
        try await pushChronometriesHandler(chronometries)
    }
}

func makeInMemoryCoreDataStack() throws -> CoreDataStack {
    try CoreDataStack(
        configuration: .inMemory(
            modelName: "CommonSyncTests",
            managedObjectModel: CommonSyncManagedObjectModelFactory.makeModel()
        )
    )
}
