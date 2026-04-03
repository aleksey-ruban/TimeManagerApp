import Foundation
import XCTest
import CoreNetwork
@testable import CoreAuth

final class AuthSessionTests: XCTestCase {
    func testAuthStateIsUnauthenticatedWhenThereIsNoStoredSession() async throws {
        let session = try AuthService(
            tokenStore: InMemoryTokenStore(),
            apiService: AuthAPIServiceStub(),
            deviceIDStore: DeviceIDStoreStub()
        )

        let state = await session.authState()

        XCTAssertEqual(state, .unauthenticated)
    }

    func testLoginStoresSessionAndMarksStateAsFresh() async throws {
        let tokenStore = InMemoryTokenStore()
        let apiService = AuthAPIServiceStub(
            loginResult: .success(
                AuthTokens(
                    accessToken: "new-access",
                    refreshToken: "new-refresh"
                )
            )
        )
        let session = try AuthService(
            tokenStore: tokenStore,
            apiService: apiService,
            deviceIDStore: DeviceIDStoreStub()
        )

        try await session.login(
            email: "alekseyruban555@gmail.com",
            password: "Qwert-123"
        )
        let state = await session.authState()
        let calls = await apiService.calls

        XCTAssertEqual(state, .authenticatedAndTokensFresh)
        XCTAssertEqual(
            calls,
            [.login(AuthCredentials(email: "alekseyruban555@gmail.com", password: "Qwert-123"), false)]
        )
        XCTAssertEqual(tokenStore.saveCallCount, 1)
    }

    func testAuthorizeRefreshesExpiredAccessToken() async throws {
        let storedSession = makeSession()
        let newTokens = AuthTokens(
            accessToken: "new-access",
            refreshToken: "new-refresh"
        )
        let tokenStore = InMemoryTokenStore(storedSession: storedSession)
        let apiService = AuthAPIServiceStub(refreshResult: .success(newTokens))
        let session = try AuthService(
            tokenStore: tokenStore,
            apiService: apiService,
            deviceIDStore: DeviceIDStoreStub()
        )
        try await session.recoverAuthorization(for: unauthorizedRequest())
        let request = NetworkRequest(
            method: .get,
            baseURL: URL(string: "https://example.com")!,
            path: "/me",
            requiresAuthorization: true
        )

        let authorizedRequest = try await session.authorize(request)
        let calls = await apiService.calls
        let state = await session.authState()

        XCTAssertEqual(authorizedRequest.headers["Authorization"], "Bearer new-access")
        XCTAssertEqual(state, .authenticatedAndTokensFresh)
        XCTAssertEqual(calls, [.refresh(storedSession)])
    }

    func testRecoverAuthorizationFallsBackToAutomaticLoginAfterNonRetryableRefreshFailure() async throws {
        let storedSession = makeSession()
        let automaticLoginTokens = AuthTokens(
            accessToken: "auto-access",
            refreshToken: "auto-refresh"
        )
        let apiService = AuthAPIServiceStub(
            loginResult: .success(automaticLoginTokens),
            refreshResult: .failure(NetworkError.httpStatusCode(400, Data()))
        )
        let session = try AuthService(
            tokenStore: InMemoryTokenStore(storedSession: storedSession),
            apiService: apiService,
            deviceIDStore: DeviceIDStoreStub()
        )

        let recoveredRequest = try await session.recoverAuthorization(for: unauthorizedRequest())
        let calls = await apiService.calls

        XCTAssertEqual(recoveredRequest.headers["Authorization"], "Bearer auto-access")
        XCTAssertEqual(
            calls,
            [
                .refresh(storedSession),
                .login(storedSession.credentials, true),
            ]
        )
    }

    func testRecoverAuthorizationDoesNotRefreshAgainForStaleAccessToken() async throws {
        let storedSession = StoredAuthSession(
            credentials: makeSession().credentials,
            tokens: AuthTokens(
                accessToken: "fresh-access",
                refreshToken: "fresh-refresh"
            )
        )
        let apiService = AuthAPIServiceStub()
        let session = try AuthService(
            tokenStore: InMemoryTokenStore(storedSession: storedSession),
            apiService: apiService,
            deviceIDStore: DeviceIDStoreStub()
        )
        let failedRequest = NetworkRequest(
            method: .get,
            baseURL: URL(string: "https://example.com")!,
            path: "/me",
            headers: ["Authorization": "Bearer stale-access"],
            requiresAuthorization: true
        )

        let recoveredRequest = try await session.recoverAuthorization(for: failedRequest)
        let calls = await apiService.calls

        XCTAssertEqual(recoveredRequest.headers["Authorization"], "Bearer fresh-access")
        XCTAssertTrue(calls.isEmpty)
    }

    func testAutomaticLoginRequiresManualAuthorizationOnUnauthorizedResponse() async throws {
        let storedSession = makeSession()
        let tokenStore = InMemoryTokenStore(storedSession: storedSession)
        let apiService = AuthAPIServiceStub(
            loginResult: .failure(NetworkError.httpStatusCode(401, Data())),
            refreshResult: .failure(NetworkError.httpStatusCode(400, Data()))
        )
        let session = try AuthService(
            tokenStore: tokenStore,
            apiService: apiService,
            deviceIDStore: DeviceIDStoreStub()
        )

        do {
            _ = try await session.recoverAuthorization(for: unauthorizedRequest())
            XCTFail("Expected manual authorization requirement")
        } catch let error as AuthError {
            XCTAssertEqual(error, .manualAuthorizationRequired)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let state = await session.authState()

        XCTAssertEqual(state, .unauthenticated)
        XCTAssertEqual(tokenStore.clearCallCount, 1)
    }

    func testAuthorizeUsesAutomaticLoginWhenStateSaysBothTokensExpired() async throws {
        let storedSession = makeSession()
        let tokenStore = InMemoryTokenStore(storedSession: storedSession)
        let apiService = AuthAPIServiceStub(
            loginResult: .failure(NetworkError.transportError("offline", isRetryable: true)),
            refreshResult: .failure(NetworkError.httpStatusCode(400, Data()))
        )
        let session = try AuthService(
            tokenStore: tokenStore,
            apiService: apiService,
            deviceIDStore: DeviceIDStoreStub()
        )

        do {
            _ = try await session.recoverAuthorization(for: unauthorizedRequest())
            XCTFail("Expected automatic login failure")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .transportError("offline", isRetryable: true))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let stateAfterFailure = await session.authState()

        XCTAssertEqual(stateAfterFailure, .authenticatedAndAccessAndRefreshTokensExpired)

        await apiService.setLoginResult(
            .success(
                AuthTokens(
                    accessToken: "auto-access",
                    refreshToken: "auto-refresh"
                )
            )
        )

        let request = try await session.authorize(authorizedRequest())
        let calls = await apiService.calls

        XCTAssertEqual(request.headers["Authorization"], "Bearer auto-access")
        XCTAssertEqual(
            calls,
            [
                .refresh(storedSession),
                .login(storedSession.credentials, true),
                .login(storedSession.credentials, true),
            ]
        )
    }

    func testLogoutClearsSession() async throws {
        let tokenStore = InMemoryTokenStore(storedSession: makeSession())
        let session = try AuthService(
            tokenStore: tokenStore,
            apiService: AuthAPIServiceStub(),
            deviceIDStore: DeviceIDStoreStub()
        )

        try await session.logout()

        let state = await session.authState()

        XCTAssertEqual(state, .unauthenticated)
        XCTAssertEqual(tokenStore.clearCallCount, 1)
    }

    func testAcceptAuthenticatedSessionStoresPassedTokens() async throws {
        let tokenStore = InMemoryTokenStore()
        let session = try AuthService(
            tokenStore: tokenStore,
            apiService: AuthAPIServiceStub(),
            deviceIDStore: DeviceIDStoreStub()
        )

        try await session.acceptAuthenticatedSession(
            email: "alekseyruban555@gmail.com",
            password: "Qwert-123",
            accessToken: "access-token",
            refreshToken: "refresh-token"
        )

        let request = try await session.authorize(authorizedRequest())

        XCTAssertEqual(tokenStore.storedSession?.tokens.accessToken, "access-token")
        XCTAssertEqual(request.headers["Authorization"], "Bearer access-token")
    }

    func testCurrentDeviceIDUsesStableDeviceIdentifierProvider() async throws {
        let session = try AuthService(
            tokenStore: InMemoryTokenStore(),
            apiService: AuthAPIServiceStub(),
            deviceIDStore: DeviceIDStoreStub(deviceID: "stable-device-id")
        )

        let deviceID = try await session.currentDeviceID()

        XCTAssertEqual(deviceID, "stable-device-id")
    }

    func testStateUpdatesYieldCurrentStateAtSubscriptionTime() async throws {
        let session = try AuthService(
            tokenStore: InMemoryTokenStore(),
            apiService: AuthAPIServiceStub(
                loginResult: .success(
                    AuthTokens(
                        accessToken: "new-access",
                        refreshToken: "new-refresh"
                    )
                )
            ),
            deviceIDStore: DeviceIDStoreStub()
        )

        try await session.login(
            email: "alekseyruban555@gmail.com",
            password: "Qwert-123"
        )

        let updates = await session.stateUpdates()
        var iterator = updates.makeAsyncIterator()
        let firstState = await iterator.next()

        XCTAssertEqual(firstState, .authenticatedAndTokensFresh)
    }

    private func authorizedRequest() -> NetworkRequest {
        NetworkRequest(
            method: .get,
            baseURL: URL(string: "https://example.com")!,
            path: "/me",
            requiresAuthorization: true
        )
    }

    private func unauthorizedRequest() -> NetworkRequest {
        authorizedRequest()
    }
}
