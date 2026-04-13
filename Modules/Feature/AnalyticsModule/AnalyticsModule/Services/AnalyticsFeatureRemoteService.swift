import CoreNetwork
import Foundation

protocol AnalyticsFeatureRemoteServiceProtocol: Sendable {
    func fetchAnalytics(for chronometryRemoteID: Int64) async throws -> CachedChronometryAnalytics?
}

actor AnalyticsFeatureRemoteService: AnalyticsFeatureRemoteServiceProtocol {
    private let executorFactory: NetworkExecutorFactoryProtocol
    private let configuration: AnalyticsFeatureAPIConfiguration
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    init(
        executorFactory: NetworkExecutorFactoryProtocol,
        configuration: AnalyticsFeatureAPIConfiguration
    ) {
        self.executorFactory = executorFactory
        self.configuration = configuration

        let jsonDecoder = JSONDecoder()
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = JSONEncoder()
    }

    func fetchAnalytics(for chronometryRemoteID: Int64) async throws -> CachedChronometryAnalytics? {
        let requestBody = try jsonEncoder.encode(AnalyticsRequest(id: chronometryRemoteID))
        let request = NetworkRequest(
            method: .post,
            baseURL: configuration.baseURL,
            path: configuration.analyticsPath,
            headers: [
                "Accept": "application/json",
            ],
            body: .data(requestBody, contentType: "application/json"),
            requiresAuthorization: true,
            retryPolicy: .none,
            idempotency: .unsafe
        )

        let executor = executorFactory.makeExecutor()
        let parser = Parser<APIResponse<RemoteChronometryAnalyticsDTO>>(decoder: jsonDecoder)
        let response = try await executor.execute(request, parser: parser)

        guard let payload = response.data else {
            return nil
        }

        return try payload.toCachedModel(cachedAt: Date())
    }
}
