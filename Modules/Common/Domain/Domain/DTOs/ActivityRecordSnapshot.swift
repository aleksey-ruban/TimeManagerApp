import Foundation

public struct ActivityRecordSnapshot: Sendable, Hashable {
    public let remoteID: Int64?
    public let globalActivityRecordID: Int64?
    public let activitySnapshotRemoteID: Int64?
    public let variationSnapshotRemoteID: Int64?
    public let startedAt: Date
    public let endedAt: Date?
    public let timeZone: String

    public init(
        remoteID: Int64?,
        globalActivityRecordID: Int64?,
        activitySnapshotRemoteID: Int64?,
        variationSnapshotRemoteID: Int64?,
        startedAt: Date,
        endedAt: Date?,
        timeZone: String
    ) {
        self.remoteID = remoteID
        self.globalActivityRecordID = globalActivityRecordID
        self.activitySnapshotRemoteID = activitySnapshotRemoteID
        self.variationSnapshotRemoteID = variationSnapshotRemoteID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.timeZone = timeZone
    }
}
