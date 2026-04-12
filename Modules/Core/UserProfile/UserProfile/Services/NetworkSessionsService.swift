import CoreAuth
import CoreNetwork
import Foundation

actor NetworkSessionsService {
    private let executorFactory: NetworkExecutorFactoryProtocol
    private let configuration: UserProfileAPIConfiguration
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        executorFactory: NetworkExecutorFactoryProtocol,
        configuration: UserProfileAPIConfiguration
    ) {
        self.executorFactory = executorFactory
        self.configuration = configuration

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(ServerDateDecoder.decode)
        self.decoder = decoder
        self.encoder = JSONEncoder()
    }

    func fetchSessions() async throws -> UserSessions {
        let executor = executorFactory.makeExecutor()
        let request = NetworkRequest(
            method: .get,
            baseURL: configuration.baseURL,
            path: configuration.sessionsPath,
            cachePolicy: .reloadIgnoringLocalCacheData,
            requiresAuthorization: true
        )

        return try await executor.execute(
            request,
            parser: Parser<UserSessions>(decoder: decoder)
        )
    }

    func logoutDevice(sessionID: Int64) async throws {
        let executor = executorFactory.makeExecutor()
        let request = try makeRequest(
            path: configuration.logoutDevicePath,
            body: LogoutDeviceRequestBody(sessionId: sessionID)
        )

        _ = try await executor.execute(request)
    }

    func logoutOtherDevices() async throws {
        let executor = executorFactory.makeExecutor()
        let request = NetworkRequest(
            method: .post,
            baseURL: configuration.baseURL,
            path: configuration.logoutOthersPath,
            headers: [
                "Accept": "application/json",
            ],
            requiresAuthorization: true,
            retryPolicy: .none,
            idempotency: .key(UUID().uuidString.lowercased())
        )

        _ = try await executor.execute(request)
    }

    private func makeRequest<Body: Encodable>(
        path: String,
        body: Body
    ) throws -> NetworkRequest {
        let bodyData = try encoder.encode(body)
        return NetworkRequest(
            method: .post,
            baseURL: configuration.baseURL,
            path: path,
            headers: [
                "Accept": "application/json",
            ],
            body: .data(bodyData, contentType: "application/json"),
            requiresAuthorization: true,
            retryPolicy: .none,
            idempotency: .key(UUID().uuidString.lowercased())
        )
    }
}

private struct LogoutDeviceRequestBody: Encodable {
    let sessionId: Int64
}
