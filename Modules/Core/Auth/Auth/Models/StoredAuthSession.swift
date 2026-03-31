import Foundation

struct StoredAuthSession: Sendable, Codable, Equatable {
    let credentials: AuthCredentials
    let tokens: AuthTokens

    init(credentials: AuthCredentials, tokens: AuthTokens) {
        self.credentials = credentials
        self.tokens = tokens
    }

    func updatingTokens(_ tokens: AuthTokens) -> StoredAuthSession {
        StoredAuthSession(credentials: credentials, tokens: tokens)
    }
}
