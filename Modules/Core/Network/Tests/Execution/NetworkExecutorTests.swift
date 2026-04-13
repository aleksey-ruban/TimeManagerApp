import Foundation
import XCTest
@testable import CoreNetwork

final class NetworkExecutorTests: XCTestCase {
    func testNetworkExecutorParsesDecodedEntity() async throws {
        let client = NetworkClientStub(
            response: NetworkResponse(
                data: Data("{\"id\":7,\"title\":\"Focus\"}".utf8),
                response: httpResponse(statusCode: 200)
            )
        )
        let executor = NetworkExecutor(client: client)
        let request = NetworkRequest(
            method: .get,
            baseURL: URL(string: "https://example.com")!,
            path: "tasks/7"
        )
        let parser = Parser<TaskPayload>()

        let parsed = try await executor.execute(request, parser: parser)

        XCTAssertEqual(parsed, TaskPayload(id: 7, title: "Focus"))
    }
}
