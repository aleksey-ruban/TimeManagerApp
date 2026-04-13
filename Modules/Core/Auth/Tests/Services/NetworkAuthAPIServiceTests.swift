import Foundation
import XCTest
@testable import CoreAuth

final class NetworkAuthAPIServiceTests: XCTestCase {
    func testLoginBuildsRequestWithStableDeviceIdentity() async throws {
        let executor = NetworkExecutorStub(
            result: .success(
                Data(#"{"accessToken":"access","refreshToken":"refresh"}"#.utf8)
            )
        )
        let service = NetworkAuthAPIService(
            networkExecutorFactory: NetworkExecutorFactoryStub(executor: executor),
            configuration: AuthAPIConfiguration(baseURL: URL(string: "https://example.com")!),
            deviceIDStore: DeviceIDStoreStub(deviceID: "device-id"),
            deviceModelProvider: DeviceModelProviderStub(model: "iPhone 16 Pro Black")
        )

        _ = try await service.login(
            with: AuthCredentials(email: "user@example.com", password: "secret"),
            isAutomatic: true
        )

        let request = try XCTUnwrap(executor.executedRequests.first)
        let payload = try XCTUnwrap(request.body?.data)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: payload) as? [String: Any])

        XCTAssertEqual(request.path, "/api/v1/auth/login")
        XCTAssertEqual(json["email"] as? String, "user@example.com")
        XCTAssertEqual(json["password"] as? String, "secret")
        XCTAssertEqual(json["deviceId"] as? String, "device-id")
        XCTAssertEqual(json["deviceModel"] as? String, "iPhone 16 Pro Black")
        XCTAssertEqual(json["isAutomatic"] as? Bool, true)
        XCTAssertFalse((request.headers["Idempotency-Key"] ?? "").isEmpty)
    }

    func testRefreshBuildsRequestWithIdempotencyKey() async throws {
        let executor = NetworkExecutorStub(
            result: .success(
                Data(#"{"accessToken":"access","refreshToken":"refresh"}"#.utf8)
            )
        )
        let service = NetworkAuthAPIService(
            networkExecutorFactory: NetworkExecutorFactoryStub(executor: executor),
            configuration: AuthAPIConfiguration(baseURL: URL(string: "https://example.com")!),
            deviceIDStore: DeviceIDStoreStub(deviceID: "device-id"),
            deviceModelProvider: DeviceModelProviderStub(model: "iPhone 16 Pro Black")
        )

        _ = try await service.refresh(session: makeSession())

        let request = try XCTUnwrap(executor.executedRequests.first)
        let payload = try XCTUnwrap(request.body?.data)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: payload) as? [String: Any])

        XCTAssertEqual(request.path, "/api/v1/auth/refresh-tokens")
        XCTAssertEqual(json["refreshToken"] as? String, "refresh-token")
        XCTAssertFalse((request.headers["Idempotency-Key"] ?? "").isEmpty)
    }
}
