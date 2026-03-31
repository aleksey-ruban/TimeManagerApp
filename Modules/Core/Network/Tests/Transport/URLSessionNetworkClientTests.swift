import Foundation
import XCTest
@testable import CoreNetwork

final class URLSessionNetworkClientTests: XCTestCase {
    func testURLSessionNetworkClientReturnsSuccessfulHTTPResponse() async throws {
        let session = URLSessionStub(
            result: .success((
                Data("{\"status\":\"ok\"}".utf8),
                httpResponse(statusCode: 200)
            ))
        )
        let client = URLSessionNetworkClient(session: session)
        let request = NetworkRequest(
            method: .get,
            baseURL: URL(string: "https://example.com")!,
            path: "health"
        )

        let response = try await client.execute(request)

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(session.capturedRequest?.url?.absoluteString, "https://example.com/health")
        XCTAssertEqual(session.capturedRequest?.httpMethod, "GET")
    }

    func testURLSessionNetworkClientMapsHTTPErrorResponse() async {
        let session = URLSessionStub(
            result: .success((
                Data("{\"message\":\"server error\"}".utf8),
                httpResponse(statusCode: 503)
            ))
        )
        let client = URLSessionNetworkClient(session: session)
        let request = NetworkRequest(
            method: .get,
            baseURL: URL(string: "https://example.com")!,
            path: "health"
        )

        do {
            _ = try await client.execute(request)
            XCTFail("Expected request to fail")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .httpStatusCode(503, Data("{\"message\":\"server error\"}".utf8)))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testURLSessionNetworkClientThrowsInvalidResponseForNonHTTPURLResponse() async {
        let session = URLSessionStub(
            result: .success((
                Data(),
                URLResponse(
                    url: URL(string: "https://example.com/health")!,
                    mimeType: nil,
                    expectedContentLength: 0,
                    textEncodingName: nil
                )
            ))
        )
        let client = URLSessionNetworkClient(session: session)
        let request = NetworkRequest(
            method: .get,
            baseURL: URL(string: "https://example.com")!,
            path: "health"
        )

        do {
            _ = try await client.execute(request)
            XCTFail("Expected request to fail")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
