import CoreNetwork
import Domain
import Foundation
import XCTest
@testable import CommonSync

final class NetworkSyncRemoteAPIServiceTests: XCTestCase {
    func testPushCategoriesSetsIdempotencyKey() async throws {
        let executor = NetworkExecutorSpy()
        let service = NetworkSyncRemoteAPIService(
            executorFactory: NetworkExecutorFactorySpy(executor: executor),
            configuration: SyncAPIConfiguration(baseURL: URL(string: "https://example.com")!)
        )

        _ = try await service.pushCategories([
            Category(
                localID: UUID(),
                remoteID: nil,
                lastModifiedVersion: nil,
                baseName: "Gym",
                code: nil,
                isDirty: true,
                isDeleted: false
            )
        ])

        let request = try XCTUnwrap(await executor.lastRequest)
        XCTAssertEqual(request.path, "/api/v1/activities/sync/push")
        XCTAssertNotNil(request.headers["Content-Type"])

        if case let .key(key) = request.idempotency {
            XCTAssertFalse(key.isEmpty)
        } else {
            XCTFail("Expected idempotency key for sync push request")
        }
    }
}

private actor NetworkExecutorSpy: INetworkExecutor {
    private(set) var lastRequest: NetworkRequest?

    func execute<Output>(
        _ request: NetworkRequest,
        parser: Parser<Output>
    ) async throws -> Output where Output: Decodable {
        lastRequest = request
        let data = Data(#"{"results":[]}"#.utf8)
        return try parser.parse(data)
    }
}

private struct NetworkExecutorFactorySpy: NetworkExecutorFactoryProtocol {
    let executor: INetworkExecutor

    func makeExecutor() -> INetworkExecutor {
        executor
    }
}
