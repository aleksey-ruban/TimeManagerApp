import CoreNetwork
import Domain
import Foundation

public final class NetworkSyncRemoteAPIService: SyncRemoteAPIServiceProtocol, @unchecked Sendable {
    private let executorFactory: NetworkExecutorFactoryProtocol
    private let configuration: SyncAPIConfiguration
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        executorFactory: NetworkExecutorFactoryProtocol,
        configuration: SyncAPIConfiguration
    ) {
        self.executorFactory = executorFactory
        self.configuration = configuration

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func fetchPullBatch(after cursor: String?, clientSnapshotVersion: SnapshotVersion) async throws -> SyncPullBatchResponseDTO? {
        let executor = executorFactory.makeExecutor()
        let requestBody = SyncPullRequestDTO(
            clientSnapshotVersion: clientSnapshotVersion,
            batchSize: cursor == nil ? configuration.initialPullBatchSize : nil,
            cursor: cursor
        )
        let body = try encoder.encode(requestBody)
        let request = NetworkRequest(
            method: .post,
            baseURL: configuration.baseURL,
            path: configuration.pullPath,
            headers: ["Content-Type": "application/json"],
            body: .data(body, contentType: "application/json"),
            requiresAuthorization: true
        )

        let parser = Parser<SyncPullBatchResponseDTO>(decoder: decoder)
        return try await executor.execute(request, parser: parser)
    }

    public func pushCategories(_ categories: [Domain.Category]) async throws -> [SyncPushResultDTO] {
        try await executePush(
            objects: categories.map { $0.makePushRequestObject() }
        )
    }

    public func pushActivities(_ activities: [Domain.Activity]) async throws -> [SyncPushResultDTO] {
        try await executePush(
            objects: activities.map { $0.makePushRequestObject() }
        )
    }

    public func pushActivityRecords(_ records: [Domain.ActivityRecord]) async throws -> [SyncPushResultDTO] {
        try await executePush(
            objects: records.map { $0.makePushRequestObject() }
        )
    }

    public func pushChronometries(
        _ chronometries: [Domain.Chronometry],
        accountSnapshotVersion: SnapshotVersion
    ) async throws -> [SyncPushResultDTO] {
        try await executePush(
            objects: chronometries.map { $0.makePushRequestObject(accountSnapshotVersion: accountSnapshotVersion) }
        )
    }

    private func executePush(objects: [SyncPushRequestObjectDTO]) async throws -> [SyncPushResultDTO] {
        let executor = executorFactory.makeExecutor()
        let body = try encoder.encode(SyncPushRequestDTO(objects: objects))
        let request = NetworkRequest(
            method: .post,
            baseURL: configuration.baseURL,
            path: configuration.pushPath,
            headers: ["Content-Type": "application/json"],
            body: .data(body, contentType: "application/json"),
            requiresAuthorization: true,
            idempotency: .key(UUID().uuidString.lowercased())
        )

        let parser = Parser<SyncPushResponseDTO>(decoder: decoder)
        let response = try await executor.execute(request, parser: parser)
        return response.results
    }
}
