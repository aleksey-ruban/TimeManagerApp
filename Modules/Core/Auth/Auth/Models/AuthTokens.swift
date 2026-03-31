import Foundation

struct AuthTokens: Sendable, Codable, Equatable {
    let accessToken: String
    let refreshToken: String

    init(
        accessToken: String,
        refreshToken: String
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
