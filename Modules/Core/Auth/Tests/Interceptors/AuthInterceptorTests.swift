import Foundation
import XCTest
import CoreNetwork
@testable import CoreAuth

final class AuthInterceptorTests: XCTestCase {
    func testAuthInterceptorForwardsNonAuthorizedRequestsWithoutSessionInteraction() async throws {
        let session = try AuthService(
            tokenStore: InMemoryTokenStore(),
            apiService: AuthAPIServiceStub(),
            deviceIDStore: DeviceIDStoreStub(),
            sessionCleanupRegistry: AuthSessionCleanupRegistry()
        )
        let client = NetworkClientQueueStub(
            results: [
                .success(NetworkResponse(data: Data(), response: httpResponse(statusCode: 200)))
            ]
        )
        let interceptor = AuthInterceptor(authSession: session)
        interceptor.setNextClient(client)
        let request = NetworkRequest(
            method: .get,
            baseURL: URL(string: "https://example.com")!,
            path: "/public"
        )

        let response = try await interceptor.execute(request)

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertTrue(client.requests[0].headers["Authorization"] == nil)
    }

    func testAuthInterceptorRetriesRequestAfterUnauthorizedResponse() async throws {
        let storedSession = makeSession()
        let tokenStore = InMemoryTokenStore(storedSession: storedSession)
        let apiService = AuthAPIServiceStub(
            refreshResult: .success(
                AuthTokens(
                    accessToken: "refreshed-access",
                    refreshToken: "refreshed-refresh"
                )
            )
        )
        let session = try AuthService(
            tokenStore: tokenStore,
            apiService: apiService,
            deviceIDStore: DeviceIDStoreStub(),
            sessionCleanupRegistry: AuthSessionCleanupRegistry()
        )
        let client = NetworkClientQueueStub(
            results: [
                .failure(NetworkError.httpStatusCode(401, Data())),
                .success(NetworkResponse(data: Data(), response: httpResponse(statusCode: 200)))
            ]
        )
        let interceptor = AuthInterceptor(authSession: session)
        interceptor.setNextClient(client)
        let request = NetworkRequest(
            method: .get,
            baseURL: URL(string: "https://example.com")!,
            path: "/me",
            requiresAuthorization: true
        )

        let response = try await interceptor.execute(request)

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].headers["Authorization"], "Bearer access-token")
        XCTAssertEqual(client.requests[1].headers["Authorization"], "Bearer refreshed-access")
        XCTAssertEqual(tokenStore.saveCallCount, 1)
    }

    func testAuthInterceptorStopsWhenManualAuthorizationIsRequired() async throws {
        let interceptor = AuthInterceptor(
            authSession: try AuthService(
                tokenStore: InMemoryTokenStore(),
                apiService: AuthAPIServiceStub(),
                deviceIDStore: DeviceIDStoreStub(),
                sessionCleanupRegistry: AuthSessionCleanupRegistry()
            )
        )
        let client = NetworkClientQueueStub(results: [])
        interceptor.setNextClient(client)
        let request = NetworkRequest(
            method: .get,
            baseURL: URL(string: "https://example.com")!,
            path: "/me",
            requiresAuthorization: true
        )

        do {
            _ = try await interceptor.execute(request)
            XCTFail("Expected manual authorization requirement")
        } catch let error as AuthError {
            XCTAssertEqual(error, .manualAuthorizationRequired)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(client.requests.isEmpty)
    }
}
