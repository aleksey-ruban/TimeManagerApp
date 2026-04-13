import Foundation
import XCTest
@testable import CoreNetwork

final class NetworkLoggerTests: XCTestCase {
    func testNetworkLoggerWritesFormattedRequestWhenEnabled() {
        let writer = NetworkLogWriterSpy()
        let logger = NetworkLogger(configuration: .enabled, writer: writer)
        var request = URLRequest(url: URL(string: "https://example.com/api/profile?locale=ru&page=1")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Authorization": "Bearer token",
            "Cookie": "session=abc; theme=dark",
            "Content-Type": "application/json",
        ]
        request.httpBody = Data(#"{"name":"Alex"}"#.utf8)

        logger.logRequest(request)

        XCTAssertEqual(writer.messages.count, 1)
        let message = try? XCTUnwrap(writer.messages.first)
        XCTAssertNotNil(message)
        XCTAssertTrue(message?.contains("[Network] POST /api/profile") == true)
        XCTAssertTrue(message?.contains("Parameters: locale=ru, page=1") == true)
        XCTAssertTrue(message?.contains(#"Body: {"name":"Alex"}"#) == true)
        XCTAssertTrue(message?.contains("Authorization: Bearer token") == true)
        XCTAssertTrue(message?.contains("Content-Type: application/json") == true)
        XCTAssertTrue(message?.contains("Cookies: session=abc, theme=dark") == true)
    }

    func testNetworkLoggerDoesNotWriteWhenDisabled() {
        let writer = NetworkLogWriterSpy()
        let logger = NetworkLogger(configuration: .disabled, writer: writer)
        let request = URLRequest(url: URL(string: "https://example.com/api/profile")!)

        logger.logRequest(request)

        XCTAssertTrue(writer.messages.isEmpty)
    }
}
