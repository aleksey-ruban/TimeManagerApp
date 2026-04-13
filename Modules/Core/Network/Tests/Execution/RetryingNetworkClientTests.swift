import Foundation
import XCTest
@testable import CoreNetwork

final class RetryingNetworkClientTests: XCTestCase {
    func testRetryingNetworkClientRetriesRetryableServerErrorsForSafeRequest() async throws {
        let nextClient = FlakyNetworkClient(
            results: [
                .failure(.httpStatusCode(503, Data())),
                .success(NetworkResponse(data: Data("ok".utf8), response: httpResponse(statusCode: 200)))
            ]
        )
        let client = RetryingNetworkClient(
            nextClient: nextClient,
            retryDelayStrategy: ImmediateRetryDelayStrategy()
        )
        let request = NetworkRequest(
            method: .get,
            baseURL: URL(string: "https://example.com")!,
            path: "tasks",
            retryPolicy: .safeMethods
        )

        let response = try await client.execute(request)

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(nextClient.executionCount, 2)
    }

    func testRetryingNetworkClientDoesNotRetryUnsafeRequest() async {
        let nextClient = FlakyNetworkClient(
            results: [
                .failure(.httpStatusCode(503, Data()))
            ]
        )
        let client = RetryingNetworkClient(
            nextClient: nextClient,
            retryDelayStrategy: ImmediateRetryDelayStrategy()
        )
        let request = NetworkRequest(
            method: .post,
            baseURL: URL(string: "https://example.com")!,
            path: "tasks",
            retryPolicy: .safeMethods
        )

        do {
            _ = try await client.execute(request)
            XCTFail("Expected request to fail")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .httpStatusCode(503, Data()))
            XCTAssertEqual(nextClient.executionCount, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRetryingNetworkClientRetriesRetryableTransportError() async throws {
        let nextClient = FlakyNetworkClient(
            results: [
                .failure(.transportError("offline", isRetryable: true)),
                .success(NetworkResponse(data: Data("{}".utf8), response: httpResponse(statusCode: 200)))
            ]
        )
        let client = RetryingNetworkClient(
            nextClient: nextClient,
            retryDelayStrategy: ImmediateRetryDelayStrategy()
        )
        let request = NetworkRequest(
            method: .get,
            baseURL: URL(string: "https://example.com")!,
            path: "status",
            retryPolicy: .safeMethods
        )

        _ = try await client.execute(request)

        XCTAssertEqual(nextClient.executionCount, 2)
    }

    func testRetryingNetworkClientMapsRawOfflineURLErrorWhenRetriesAreExhausted() async {
        let nextClient = RawErrorFlakyNetworkClient(
            results: Array(
                repeating: .failure(URLError(.notConnectedToInternet)),
                count: 4
            )
        )
        let client = RetryingNetworkClient(
            nextClient: nextClient,
            retryDelayStrategy: ImmediateRetryDelayStrategy()
        )
        let request = NetworkRequest(
            method: .get,
            baseURL: URL(string: "https://example.com")!,
            path: "status",
            retryPolicy: .safeMethods
        )

        do {
            _ = try await client.execute(request)
            XCTFail("Expected request to fail")
        } catch let error as NetworkError {
            XCTAssertEqual(
                error,
                .transportError(URLError(.notConnectedToInternet).localizedDescription, isRetryable: true)
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private final class RawErrorFlakyNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    private var results: [Result<NetworkResponse, Error>]

    init(results: [Result<NetworkResponse, Error>]) {
        self.results = results
    }

    func execute(_ request: NetworkRequest) async throws -> NetworkResponse {
        try results.removeFirst().get()
    }
}
