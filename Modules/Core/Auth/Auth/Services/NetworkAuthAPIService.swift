import Foundation
import CoreNetwork

struct NetworkAuthAPIService: AuthAPIServiceProtocol {
    private let networkExecutorFactory: NetworkExecutorFactoryProtocol
    private let configuration: AuthAPIConfiguration
    private let deviceIDStore: DeviceIDStoreProtocol
    private let deviceModelProvider: DeviceModelProviderProtocol
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    init(
        networkExecutorFactory: NetworkExecutorFactoryProtocol,
        configuration: AuthAPIConfiguration,
        deviceIDStore: DeviceIDStoreProtocol,
        deviceModelProvider: DeviceModelProviderProtocol,
        jsonDecoder: JSONDecoder = JSONDecoder(),
        jsonEncoder: JSONEncoder = JSONEncoder()
    ) {
        self.networkExecutorFactory = networkExecutorFactory
        self.configuration = configuration
        self.deviceIDStore = deviceIDStore
        self.deviceModelProvider = deviceModelProvider
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
    }

    func login(with credentials: AuthCredentials, isAutomatic: Bool) async throws -> AuthTokens {
        let deviceID = try deviceIDStore.loadOrCreateDeviceID()
        let deviceModel = await deviceModelProvider.deviceModel()
        let requestBody = LoginRequestBody(
            email: credentials.email,
            password: credentials.password,
            deviceId: deviceID,
            deviceModel: deviceModel,
            isAutomatic: isAutomatic
        )
        let request = try makeRequest(
            path: configuration.loginPath,
            body: requestBody,
            idempotencyKey: UUID().uuidString.lowercased()
        )
        let executor = networkExecutorFactory.makeExecutor()
        let parser = Parser<AuthTokensPayload>(decoder: jsonDecoder)
        let payload = try await executor.execute(request, parser: parser)
        return try makeTokens(from: payload, fallbackRefreshToken: nil)
    }

    func refresh(session: StoredAuthSession) async throws -> AuthTokens {
        let requestBody = RefreshRequestBody(
            refreshToken: session.tokens.refreshToken
        )
        let request = try makeRequest(
            path: configuration.refreshPath,
            body: requestBody,
            idempotencyKey: UUID().uuidString.lowercased()
        )
        let executor = networkExecutorFactory.makeExecutor()
        let parser = Parser<AuthTokensPayload>(decoder: jsonDecoder)
        let payload = try await executor.execute(request, parser: parser)
        return try makeTokens(
            from: payload,
            fallbackRefreshToken: session.tokens.refreshToken
        )
    }

    private func makeRequest<Body: Encodable>(
        path: String,
        body: Body,
        idempotencyKey: String
    ) throws -> NetworkRequest {
        let bodyData = try jsonEncoder.encode(body)
        return NetworkRequest(
            method: .post,
            baseURL: configuration.baseURL,
            path: path,
            headers: [
                "Accept": "application/json",
            ],
            body: .data(bodyData, contentType: "application/json"),
            retryPolicy: .none,
            idempotency: .key(idempotencyKey)
        )
    }

    private func makeTokens(
        from payload: AuthTokensPayload,
        fallbackRefreshToken: String?
    ) throws -> AuthTokens {
        guard
            let accessToken = payload.accessToken,
            let refreshToken = payload.refreshToken ?? fallbackRefreshToken
        else {
            throw AuthError.invalidAuthResponse
        }

        return AuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
}

private struct LoginRequestBody: Encodable {
    let email: String
    let password: String
    let deviceId: String
    let deviceModel: String
    let isAutomatic: Bool
}

private struct RefreshRequestBody: Encodable {
    let refreshToken: String
}

private struct AuthTokensPayload: Decodable {
    let accessToken: String?
    let refreshToken: String?
}
