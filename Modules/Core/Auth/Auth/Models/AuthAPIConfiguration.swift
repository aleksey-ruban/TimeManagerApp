import Foundation

public struct AuthAPIConfiguration: Sendable, Equatable {
    public let baseURL: URL
    public let loginPath: String
    public let refreshPath: String

    public init(
        baseURL: URL,
        loginPath: String = "/api/v1/auth/login",
        refreshPath: String = "/api/v1/auth/refresh-tokens"
    ) {
        self.baseURL = baseURL
        self.loginPath = loginPath
        self.refreshPath = refreshPath
    }
}
