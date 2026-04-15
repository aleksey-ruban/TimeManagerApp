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

        let request = try XCTUnwrap(executor.lastRequest)
        XCTAssertEqual(request.path, "/api/v1/activities/sync/push")
        XCTAssertNotNil(request.headers["Content-Type"])

        if case let .key(key) = request.idempotency {
            XCTAssertFalse(key.isEmpty)
        } else {
            XCTFail("Expected idempotency key for sync push request")
        }
    }

    func testPushActivitiesIncludesVariationIDsForExistingVariations() async throws {
        let executor = NetworkExecutorSpy()
        let service = NetworkSyncRemoteAPIService(
            executorFactory: NetworkExecutorFactorySpy(executor: executor),
            configuration: SyncAPIConfiguration(baseURL: URL(string: "https://example.com")!)
        )

        _ = try await service.pushActivities([
            Activity(
                localID: UUID(uuidString: "D770B0ED-5C3F-4324-AB7E-D79A31F0FCE8")!,
                remoteID: 133,
                lastModifiedVersion: 23,
                name: "Diploma",
                categoryLocalID: nil,
                categoryRemoteID: 27,
                iconName: "fork.knife",
                color: .green,
                variations: [
                    ActivityVariation(
                        localID: UUID(),
                        remoteID: 901,
                        value: "iOS",
                        position: 0,
                        isDeleted: false
                    ),
                    ActivityVariation(
                        localID: UUID(),
                        remoteID: nil,
                        value: "Backend",
                        position: 1,
                        isDeleted: false
                    ),
                ],
                isDirty: true,
                isDeleted: false
            )
        ])

        let request = try XCTUnwrap(executor.lastRequest)
        guard case let .data(body, _) = try XCTUnwrap(request.body) else {
            return XCTFail("Expected data body")
        }

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let objects = try XCTUnwrap(json["objects"] as? [[String: Any]])
        let payload = try XCTUnwrap(objects.first?["payload"] as? [String: Any])
        let variations = try XCTUnwrap(payload["variations"] as? [[String: Any]])

        XCTAssertEqual(variations.count, 2)
        XCTAssertEqual((variations[0]["id"] as? NSNumber)?.int64Value, 901)
        XCTAssertNil(variations[1]["id"])
    }

    func testPushChronometriesUsesCurrentTimeForFinishTime() async throws {
        let executor = NetworkExecutorSpy()
        let service = NetworkSyncRemoteAPIService(
            executorFactory: NetworkExecutorFactorySpy(executor: executor),
            configuration: SyncAPIConfiguration(baseURL: URL(string: "https://example.com")!)
        )

        let staleEndDate = Date(timeIntervalSince1970: 1_744_502_400)
        let beforePush = Date()

        _ = try await service.pushChronometries(
            [
                Chronometry(
                    localID: UUID(uuidString: "3BF29795-7A11-46CB-BED7-90435FBB559E")!,
                    remoteID: 6,
                    lastModifiedVersion: 37,
                    startDate: Date(timeIntervalSince1970: 1_744_070_400),
                    endDate: staleEndDate,
                    isFinished: true,
                    timeZone: "Europe/Moscow",
                    categorySnapshots: [],
                    activitySnapshots: [],
                    activityRecordSnapshots: [],
                    isDirty: true,
                    isDeleted: false
                )
            ],
            accountSnapshotVersion: SnapshotVersion(Int64(51))
        )

        let afterPush = Date()
        let request = try XCTUnwrap(executor.lastRequest)
        guard case let .data(body, _) = try XCTUnwrap(request.body) else {
            return XCTFail("Expected data body")
        }

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let objects = try XCTUnwrap(json["objects"] as? [[String: Any]])
        let payload = try XCTUnwrap(objects.first?["payload"] as? [String: Any])
        let finishTimeString = try XCTUnwrap(payload["finishTime"] as? String)
        let snapshotVersion = try XCTUnwrap(payload["snapshotVersion"] as? NSNumber)

        let formatter = ISO8601DateFormatter()
        let finishTime = try XCTUnwrap(formatter.date(from: finishTimeString))

        XCTAssertNotEqual(finishTime, staleEndDate)
        XCTAssertEqual(snapshotVersion.int64Value, 51)
        XCTAssertGreaterThanOrEqual(finishTime.timeIntervalSince1970, beforePush.timeIntervalSince1970 - 1)
        XCTAssertLessThanOrEqual(finishTime.timeIntervalSince1970, afterPush.timeIntervalSince1970 + 1)
    }
}

private final class NetworkExecutorSpy: INetworkExecutor, @unchecked Sendable {
    private let lock = NSLock()
    private var _lastRequest: NetworkRequest?

    var lastRequest: NetworkRequest? {
        lock.withLock {
            _lastRequest
        }
    }

    func execute(_ request: NetworkRequest) async throws -> NetworkResponse {
        record(request)
        return NetworkResponse(
            data: Data(#"{"message":"OK","data":{"results":[]}}"#.utf8),
            response: httpResponse(statusCode: 200)
        )
    }

    func execute<Output>(
        _ request: NetworkRequest,
        parser: Parser<Output>
    ) async throws -> Output where Output: Decodable {
        record(request)
        let data = Data(#"{"message":"OK","data":{"results":[]}}"#.utf8)
        return try parser.parse(data)
    }

    private func record(_ request: NetworkRequest) {
        lock.withLock {
            _lastRequest = request
        }
    }
}

private struct NetworkExecutorFactorySpy: NetworkExecutorFactoryProtocol {
    let executor: INetworkExecutor

    func makeExecutor() -> INetworkExecutor {
        executor
    }
}

private func httpResponse(statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(
        url: URL(string: "https://example.com")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
    )!
}

private extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
