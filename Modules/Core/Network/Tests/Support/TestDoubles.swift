import Foundation
@testable import CoreNetwork

final class NetworkClientSpy: NetworkClientProtocol, @unchecked Sendable {
    private let responseData: Data
    private(set) var executedRequests: [NetworkRequest] = []

    init(responseData: Data) {
        self.responseData = responseData
    }

    func execute(_ request: NetworkRequest) async throws -> NetworkResponse {
        executedRequests.append(request)
        return NetworkResponse(data: responseData, response: httpResponse(statusCode: 200))
    }
}

final class NetworkClientStub: NetworkClientProtocol, @unchecked Sendable {
    private let response: NetworkResponse

    init(response: NetworkResponse) {
        self.response = response
    }

    func execute(_ request: NetworkRequest) async throws -> NetworkResponse {
        response
    }
}

final class AuthInterceptorSpy: AuthInterceptorProtocol, @unchecked Sendable {
    private let responseData: Data?
    private var nextClient: NetworkClientProtocol?
    private(set) var nextClientWasSet = false
    private(set) var forwardedRequests: [NetworkRequest] = []

    init(responseData: Data? = nil) {
        self.responseData = responseData
    }

    func setNextClient(_ client: NetworkClientProtocol) {
        nextClient = client
        nextClientWasSet = true
    }

    func execute(_ request: NetworkRequest) async throws -> NetworkResponse {
        forwardedRequests.append(request)

        if let responseData {
            return NetworkResponse(data: responseData, response: httpResponse(statusCode: 200))
        }

        guard let nextClient else {
            throw NetworkError.transportError("Missing next client", isRetryable: false)
        }

        return try await nextClient.execute(request)
    }
}

struct ImmediateRetryDelayStrategy: RetryDelayStrategyProtocol {
    func delay(forAttempt attempt: Int) -> Duration {
        .zero
    }
}

final class FlakyNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    private(set) var executionCount = 0
    private var results: [Result<NetworkResponse, NetworkError>]

    init(results: [Result<NetworkResponse, NetworkError>]) {
        self.results = results
    }

    func execute(_ request: NetworkRequest) async throws -> NetworkResponse {
        executionCount += 1

        let result = results.removeFirst()
        switch result {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }
}

final class URLSessionStub: URLSessionProtocol, @unchecked Sendable {
    private let result: Result<(Data, URLResponse), Error>
    private(set) var capturedRequest: URLRequest?

    init(result: Result<(Data, URLResponse), Error>) {
        self.result = result
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        capturedRequest = request
        return try result.get()
    }
}

final class NetworkLoggerSpy: NetworkLogging, @unchecked Sendable {
    private(set) var loggedRequests: [URLRequest] = []

    func logRequest(_ request: URLRequest) {
        loggedRequests.append(request)
    }
}

final class NetworkLogWriterSpy: NetworkLogWriting, @unchecked Sendable {
    private(set) var messages: [String] = []

    func write(_ message: String) {
        messages.append(message)
    }
}
