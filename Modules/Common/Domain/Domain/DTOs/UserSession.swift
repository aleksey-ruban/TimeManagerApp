import Foundation

public struct UserSession: Sendable, Codable, Hashable {
    public let sessionID: Int64
    public let deviceModel: String
    public let createdAt: Date
    public let lastUsedAt: Date

    public init(
        sessionID: Int64,
        deviceModel: String,
        createdAt: Date,
        lastUsedAt: Date
    ) {
        self.sessionID = sessionID
        self.deviceModel = deviceModel
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }

    enum CodingKeys: String, CodingKey {
        case sessionID = "sessionId"
        case deviceModel
        case createdAt
        case lastUsedAt
    }
}
