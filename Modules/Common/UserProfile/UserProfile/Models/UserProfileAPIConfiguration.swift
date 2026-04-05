import Foundation

public struct UserProfileAPIConfiguration: Sendable, Hashable {
    public let baseURL: URL
    public let userPath: String
    public let sessionsPath: String

    public init(
        baseURL: URL,
        userPath: String = "/api/v1/auth/user",
        sessionsPath: String = "/api/v1/auth/sessions"
    ) {
        self.baseURL = baseURL
        self.userPath = userPath
        self.sessionsPath = sessionsPath
    }
}
