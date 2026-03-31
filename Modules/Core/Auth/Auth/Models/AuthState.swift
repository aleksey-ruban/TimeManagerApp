import Foundation

public enum AuthState: Sendable, Equatable {
    case unauthenticated
    case authenticatedAndTokensFresh
    case authenticatedAndAccessTokenExpired
    case authenticatedAndAccessAndRefreshTokensExpired
}
