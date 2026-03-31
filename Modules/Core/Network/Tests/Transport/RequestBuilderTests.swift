import Foundation
import XCTest
@testable import CoreNetwork

final class RequestBuilderTests: XCTestCase {
    func testRequestBuilderBuildsURLMethodHeadersBodyAndCookies() throws {
        let builder = RequestBuilder()
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
            retryPolicy: .safeMethods,
            idempotency: .key("request-1")
        )

        let urlRequest = try builder.build(from: request)

        XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/tasks?include=details")
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "X-Trace-ID"), "123")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Idempotency-Key"), "request-1")
        XCTAssertEqual(urlRequest.httpBody, body)
        XCTAssertEqual(urlRequest.timeoutInterval, 15, accuracy: 0.001)
        XCTAssertEqual(urlRequest.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(urlRequest.httpShouldHandleCookies, true)
    }
}
