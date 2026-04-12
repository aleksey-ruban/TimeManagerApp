import Foundation

public struct UserSessions: Sendable, Codable, Hashable {
    public let currentSessionID: Int64
    public let sessions: [UserSession]

    public init(
        currentSessionID: Int64,
        sessions: [UserSession]
    ) {
        self.currentSessionID = currentSessionID
        self.sessions = sessions
    }

    enum CodingKeys: String, CodingKey {
        case currentSessionID = "currentSessionId"
        case sessions
    }
}
