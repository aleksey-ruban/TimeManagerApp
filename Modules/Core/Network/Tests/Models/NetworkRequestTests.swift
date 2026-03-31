import Foundation
import XCTest
@testable import CoreNetwork

final class NetworkRequestTests: XCTestCase {
    func testNetworkRequestStoresProvidedValues() {
        let body = Data("{\"title\":\"Focus\"}".utf8)
        let request = NetworkRequest(
            method: .post,
            baseURL: URL(string: "https://example.com")!,
            path: "tasks",
            headers: ["X-Trace-ID": "123"],
            queryItems: [URLQueryItem(name: "include", value: "details")],
            body: .data(body, contentType: "application/json"),
            timeoutInterval: 15,
            cachePolicy: .reloadIgnoringLocalCacheData,
            allowsCookies: true,
            requiresAuthorization: true,
            retryPolicy: .safeMethods,
            idempotency: .key("request-1")
        )

        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.path, "tasks")
        XCTAssertEqual(request.headers["X-Trace-ID"], "123")
        XCTAssertEqual(request.queryItems, [URLQueryItem(name: "include", value: "details")])
        XCTAssertEqual(request.body?.data, body)
        XCTAssertEqual(request.body?.contentType, "application/json")
        XCTAssertEqual(request.timeoutInterval, 15)
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(request.allowsCookies, true)
        XCTAssertTrue(request.requiresAuthorization)
        XCTAssertEqual(request.retryPolicy, .safeMethods)
        XCTAssertEqual(request.idempotency, .key("request-1"))
    }
}
