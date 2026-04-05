import Foundation

public struct ActivityVariation: Sendable, Hashable {
    public let localID: UUID
    public let remoteID: Int64?
    public let value: String
    public let position: Int
    public let isDeleted: Bool

    public init(
        localID: UUID,
        remoteID: Int64?,
        value: String,
        position: Int,
        isDeleted: Bool
    ) {
        self.localID = localID
        self.remoteID = remoteID
        self.value = value
        self.position = position
        self.isDeleted = isDeleted
    }
}
