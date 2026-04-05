import Foundation

public struct ActivityRecord: Sendable, Hashable {
    public let localID: UUID
    public let remoteID: Int64?
    public let lastModifiedVersion: Int64?
    public let activityLocalID: UUID
    public let activityRemoteID: Int64?
    public let variationLocalID: UUID?
    public let variationRemoteID: Int64?
    public let startedAt: Date
    public let endedAt: Date?
    public let timeZone: String
    public let isDirty: Bool
    public let isDeleted: Bool

    public init(
        localID: UUID,
        remoteID: Int64?,
        lastModifiedVersion: Int64?,
        activityLocalID: UUID,
        activityRemoteID: Int64?,
        variationLocalID: UUID?,
        variationRemoteID: Int64?,
        startedAt: Date,
        endedAt: Date?,
        timeZone: String,
        isDirty: Bool,
        isDeleted: Bool
    ) {
        self.localID = localID
        self.remoteID = remoteID
        self.lastModifiedVersion = lastModifiedVersion
        self.activityLocalID = activityLocalID
        self.activityRemoteID = activityRemoteID
        self.variationLocalID = variationLocalID
        self.variationRemoteID = variationRemoteID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.timeZone = timeZone
        self.isDirty = isDirty
        self.isDeleted = isDeleted
    }
}
