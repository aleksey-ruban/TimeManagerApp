import Foundation
import CoreSessionCleanup
import CoreNetwork

actor AuthService: AuthSessionProtocol, AuthFeatureServiceProtocol {
    private let tokenStore: TokenStoreProtocol
    private let apiService: AuthAPIServiceProtocol
    private let deviceIDStore: DeviceIDStoreProtocol
    private let sessionCleanupRegistry: AuthSessionCleanupRegistry

    private var storedSession: StoredAuthSession?
    private var state: AuthState
    private var subscribers: [UUID: AsyncStream<AuthState>.Continuation] = [:]
    private var isRecoveryInProgress = false
    private var recoveryWaiters: [CheckedContinuation<StoredAuthSession, Error>] = []

    init(
        tokenStore: TokenStoreProtocol,
        apiService: AuthAPIServiceProtocol,
        deviceIDStore: DeviceIDStoreProtocol,
        sessionCleanupRegistry: AuthSessionCleanupRegistry
    ) throws {
        self.tokenStore = tokenStore
        self.apiService = apiService
        self.deviceIDStore = deviceIDStore
        self.sessionCleanupRegistry = sessionCleanupRegistry
        let storedSession = try tokenStore.load()
        self.storedSession = storedSession
        self.state = storedSession == nil ? .unauthenticated : .authenticatedAndTokensFresh
    }

    func authState() async -> AuthState {
        state
    }

    func launchAuthorizationState() async -> AuthLaunchAuthorizationState {
        switch state {
        case .unauthenticated:
            .unauthenticated
        case .authenticatedAndTokensFresh,
                .authenticatedAndAccessTokenExpired,
                .authenticatedAndAccessAndRefreshTokensExpired:
            .authenticated
        }
    }

    func stateUpdates() async -> AsyncStream<AuthState> {
        let identifier = UUID()

        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            Task { [weak self] in
                await self?.addSubscriber(
                    identifier: identifier,
                    continuation: continuation
                )
            }
            continuation.onTermination = { [weak self] _ in
                Task {
                    await self?.removeSubscriber(identifier)
                }
            }
        }
    }

    func login(email: String, password: String) async throws {
        let credentials = AuthCredentials(email: email, password: password)
        do {
            let tokens = try await apiService.login(with: credentials, isAutomatic: false)
            try storeAuthenticatedSession(credentials: credentials, tokens: tokens)
        } catch {
            if let sessionCleanupService = sessionCleanupRegistry.service {
                try await sessionCleanupService.clearLocalSessionArtifacts()
            }
            throw error
        }
    }

    func acceptAuthenticatedSession(
        email: String,
        password: String,
        accessToken: String,
        refreshToken: String
    ) async throws {
        let credentials = AuthCredentials(email: email, password: password)
        let tokens = AuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken
        )
        try storeAuthenticatedSession(credentials: credentials, tokens: tokens)
    }

    func currentDeviceID() throws -> String {
        try deviceIDStore.loadOrCreateDeviceID()
    }

    func logout() async throws {
        try await terminateSession()
    }

    func authorize(_ request: NetworkRequest) async throws -> NetworkRequest {
        guard request.requiresAuthorization else {
            return request
        }

        let session: StoredAuthSession

        switch state {
        case .unauthenticated:
            updateState(.unauthenticated)
            throw AuthError.manualAuthorizationRequired
        case .authenticatedAndTokensFresh:
            guard let storedSession else {
                updateState(.unauthenticated)
                throw AuthError.manualAuthorizationRequired
            }
            session = storedSession
        case .authenticatedAndAccessTokenExpired:
            session = try await recoverSession(mode: .refreshThenAutomaticLogin)
        case .authenticatedAndAccessAndRefreshTokensExpired:
            session = try await recoverSession(mode: .automaticLoginOnly)
        }

        return sign(request, accessToken: session.tokens.accessToken)
    }

    func recoverAuthorization(for failedRequest: NetworkRequest) async throws -> NetworkRequest {
        guard failedRequest.requiresAuthorization else {
            return failedRequest
        }

        if let request = resignIfRequestUsesStaleAccessToken(failedRequest) {
            return request
        }

        let mode: RecoveryMode

        switch state {
        case .unauthenticated:
            updateState(.unauthenticated)
            throw AuthError.manualAuthorizationRequired
        case .authenticatedAndTokensFresh, .authenticatedAndAccessTokenExpired:
            mode = .refreshThenAutomaticLogin
        case .authenticatedAndAccessAndRefreshTokensExpired:
            mode = .automaticLoginOnly
        }

        let session = try await recoverSession(mode: mode)
        return sign(failedRequest, accessToken: session.tokens.accessToken)
    }

    private func recoverSession(mode: RecoveryMode) async throws -> StoredAuthSession {
        if isRecoveryInProgress {
            return try await withCheckedThrowingContinuation { continuation in
                recoveryWaiters.append(continuation)
            }
        }

        isRecoveryInProgress = true

        do {
            let recoveredSession = try await performRecovery(mode: mode)
            completeRecovery(with: .success(recoveredSession))
            return recoveredSession
        } catch {
            completeRecovery(with: .failure(error))
            throw error
        }
    }

    private func performRecovery(mode: RecoveryMode) async throws -> StoredAuthSession {
        guard let snapshot = storedSession else {
            try await transitionToManualAuthorization()
            throw AuthError.manualAuthorizationRequired
        }

        switch mode {
        case .refreshThenAutomaticLogin:
            updateState(.authenticatedAndAccessTokenExpired)

            do {
                return try await refreshSession(from: snapshot)
            } catch {
                guard shouldFallbackToAutomaticLogin(for: error) else {
                    throw error
                }
            }

            updateState(.authenticatedAndAccessAndRefreshTokensExpired)
            return try await automaticLogin(with: snapshot.credentials)
        case .automaticLoginOnly:
            updateState(.authenticatedAndAccessAndRefreshTokensExpired)
            return try await automaticLogin(with: snapshot.credentials)
        }
    }

    private func refreshSession(from snapshot: StoredAuthSession) async throws -> StoredAuthSession {
        let refreshedTokens = try await apiService.refresh(session: snapshot)
        let refreshedSession = snapshot.updatingTokens(refreshedTokens)

        try tokenStore.save(refreshedSession)
        storedSession = refreshedSession
        updateState(.authenticatedAndTokensFresh)
        return refreshedSession
    }

    private func automaticLogin(with credentials: AuthCredentials) async throws -> StoredAuthSession {
        do {
            let tokens = try await apiService.login(with: credentials, isAutomatic: true)
            return try storeAuthenticatedSession(credentials: credentials, tokens: tokens)
        } catch {
            guard shouldRequireManualAuthorization(for: error) else {
                throw error
            }

            try await transitionToManualAuthorization()
            throw AuthError.manualAuthorizationRequired
        }
    }

    private func transitionToManualAuthorization() async throws {
        try await terminateSession()
    }

    private func terminateSession() async throws {
        try tokenStore.clear()
        storedSession = nil
        updateState(.unauthenticated)
    }

    @discardableResult
    private func storeAuthenticatedSession(
        credentials: AuthCredentials,
        tokens: AuthTokens
    ) throws -> StoredAuthSession {
        let session = StoredAuthSession(credentials: credentials, tokens: tokens)
        try tokenStore.save(session)
        storedSession = session
        updateState(.authenticatedAndTokensFresh)
        return session
    }

    private func sign(_ request: NetworkRequest, accessToken: String) -> NetworkRequest {
        request.addingHeader(name: "Authorization", value: "Bearer \(accessToken)")
    }

    private func resignIfRequestUsesStaleAccessToken(_ request: NetworkRequest) -> NetworkRequest? {
        guard
            let failedAccessToken = bearerToken(from: request),
            let currentAccessToken = storedSession?.tokens.accessToken,
            failedAccessToken != currentAccessToken
        else {
            return nil
        }

        return sign(request, accessToken: currentAccessToken)
    }

    private func bearerToken(from request: NetworkRequest) -> String? {
        guard let authorizationHeader = request.headers["Authorization"] else {
            return nil
        }

        let prefix = "Bearer "
        guard authorizationHeader.hasPrefix(prefix) else {
            return nil
        }

        return String(authorizationHeader.dropFirst(prefix.count))
    }

    private func completeRecovery(with result: Result<StoredAuthSession, Error>) {
        let waiters = recoveryWaiters
        recoveryWaiters.removeAll()
        isRecoveryInProgress = false

        for waiter in waiters {
            switch result {
            case let .success(session):
                waiter.resume(returning: session)
            case let .failure(error):
                waiter.resume(throwing: error)
            }
        }
    }

    private func updateState(_ newState: AuthState) {
        state = newState

        for continuation in subscribers.values {
            continuation.yield(newState)
        }
    }

    private func addSubscriber(
        identifier: UUID,
        continuation: AsyncStream<AuthState>.Continuation
    ) {
        subscribers[identifier] = continuation
        continuation.yield(state)
    }

    private func removeSubscriber(_ identifier: UUID) {
        subscribers.removeValue(forKey: identifier)
    }

    private func shouldFallbackToAutomaticLogin(for error: Error) -> Bool {
        guard let networkError = error as? NetworkError else {
            return true
        }

        switch networkError {
        case .httpStatusCode(let statusCode, _):
            return statusCode == 401 || !Self.retryableStatusCodes.contains(statusCode)
        case .transportError:
            return false
        case .invalidURL, .invalidResponse:
            return true
        }
    }

    private func shouldRequireManualAuthorization(for error: Error) -> Bool {
        guard let networkError = error as? NetworkError else {
            return true
        }

        switch networkError {
        case .httpStatusCode(let statusCode, _):
            return statusCode == 401 || !Self.retryableStatusCodes.contains(statusCode)
        case .transportError(_, let isRetryable):
            return !isRetryable
        case .invalidURL, .invalidResponse:
            return true
        }
    }

    private static let retryableStatusCodes: Set<Int> = [
        408,
        425,
        429,
        500,
        502,
        503,
        504
    ]
}

private enum RecoveryMode {
    case refreshThenAutomaticLogin
    case automaticLoginOnly
}
