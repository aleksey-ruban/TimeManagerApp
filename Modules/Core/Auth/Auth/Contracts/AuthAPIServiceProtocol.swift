import Foundation

protocol AuthAPIServiceProtocol: Sendable {
    func login(with credentials: AuthCredentials, isAutomatic: Bool) async throws -> AuthTokens
    func refresh(session: StoredAuthSession) async throws -> AuthTokens
}
