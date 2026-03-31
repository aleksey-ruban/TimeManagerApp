import Foundation
import CoreNetwork
@testable import CoreAuth

final class InMemoryTokenStore: TokenStoreProtocol, @unchecked Sendable {
    private(set) var storedSession: StoredAuthSession?
    private(set) var saveCallCount = 0
    private(set) var clearCallCount = 0

    init(storedSession: StoredAuthSession? = nil) {
        self.storedSession = storedSession
    }

    func load() throws -> StoredAuthSession? {
        storedSession
    }

    func save(_ session: StoredAuthSession) throws {
        saveCallCount += 1
        storedSession = session
    }

    func clear() throws {
        clearCallCount += 1
        storedSession = nil
    }
}

actor AuthAPIServiceStub: AuthAPIServiceProtocol {
    enum Call: Equatable {
        case login(AuthCredentials, Bool)
        case refresh(StoredAuthSession)
    }

    var loginResult: Result<AuthTokens, Error>
    var refreshResult: Result<AuthTokens, Error>
    private(set) var calls: [Call] = []

    init(
        loginResult: Result<AuthTokens, Error> = .failure(NetworkError.transportError("missing", isRetryable: false)),
        refreshResult: Result<AuthTokens, Error> = .failure(NetworkError.transportError("missing", isRetryable: false))
    ) {
        self.loginResult = loginResult
        self.refreshResult = refreshResult
    }

    func login(with credentials: AuthCredentials, isAutomatic: Bool) async throws -> AuthTokens {
        calls.append(.login(credentials, isAutomatic))
        return try loginResult.get()
    }

    func refresh(session: StoredAuthSession) async throws -> AuthTokens {
        calls.append(.refresh(session))
        return try refreshResult.get()
    }

    func setLoginResult(_ result: Result<AuthTokens, Error>) {
        loginResult = result
    }

    func setRefreshResult(_ result: Result<AuthTokens, Error>) {
        refreshResult = result
    }
}

final class DeviceIDStoreStub: DeviceIDStoreProtocol, @unchecked Sendable {
    let deviceID: String

    init(deviceID: String = "550e8400-e29b-41d4-a716-446655440005") {
        self.deviceID = deviceID
    }

    func loadOrCreateDeviceID() throws -> String {
        deviceID
    }
}

struct DeviceModelProviderStub: DeviceModelProviderProtocol {
    let model: String

    init(model: String = "iPhone 16 Pro Black") {
        self.model = model
    }

    func deviceModel() -> String {
        model
    }
}

final class NetworkClientQueueStub: NetworkClientProtocol, @unchecked Sendable {
    private var results: [Result<NetworkResponse, Error>]
    private(set) var requests: [NetworkRequest] = []

    init(results: [Result<NetworkResponse, Error>]) {
        self.results = results
    }

    func execute(_ request: NetworkRequest) async throws -> NetworkResponse {
        requests.append(request)
        return try results.removeFirst().get()
    }
}

final class NetworkExecutorStub: INetworkExecutor, @unchecked Sendable {
    let result: Result<Data, Error>
    private(set) var executedRequests: [NetworkRequest] = []

    init(result: Result<Data, Error>) {
        self.result = result
    }

    func execute<DecodedOutput: Decodable>(
        _ request: NetworkRequest,
        parser: Parser<DecodedOutput>
    ) async throws -> DecodedOutput {
        executedRequests.append(request)

        switch result {
        case let .success(data):
            return try parser.parse(data)
        case let .failure(error):
            throw error
        }
    }
}

final class NetworkExecutorFactoryStub: NetworkExecutorFactoryProtocol, @unchecked Sendable {
    private let executor: INetworkExecutor

    init(executor: INetworkExecutor) {
        self.executor = executor
    }

    func makeExecutor() -> INetworkExecutor {
        executor
    }
}

func makeSession() -> StoredAuthSession {
    StoredAuthSession(
        credentials: AuthCredentials(
            email: "alekseyruban555@gmail.com",
            password: "Qwert-123"
        ),
        tokens: AuthTokens(
            accessToken: "access-token",
            refreshToken: "refresh-token"
        )
    )
}

func httpResponse(statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(
        url: URL(string: "https://example.com")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
    )!
}
