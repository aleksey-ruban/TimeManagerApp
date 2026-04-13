import Foundation

public struct Chronometry: Sendable, Hashable {
    public let localID: UUID
    public let remoteID: Int64?
    public let lastModifiedVersion: Int64?
    public let startDate: Date
    public let endDate: Date
    public let isFinished: Bool
    public let timeZone: String
    public let categorySnapshots: [CategorySnapshot]
    public let activitySnapshots: [ActivitySnapshot]
    public let activityRecordSnapshots: [ActivityRecordSnapshot]
    public let isDirty: Bool
    public let isDeleted: Bool

    public init(
        localID: UUID,
        remoteID: Int64?,
        lastModifiedVersion: Int64?,
        startDate: Date,
        endDate: Date,
        isFinished: Bool,
        timeZone: String,
        categorySnapshots: [CategorySnapshot],
        activitySnapshots: [ActivitySnapshot],
        activityRecordSnapshots: [ActivityRecordSnapshot],
        isDirty: Bool,
        isDeleted: Bool
    ) {
        self.localID = localID
        self.remoteID = remoteID
        self.lastModifiedVersion = lastModifiedVersion
        self.startDate = startDate
        self.endDate = endDate
        self.isFinished = isFinished
        self.timeZone = timeZone
        self.categorySnapshots = categorySnapshots
        self.activitySnapshots = activitySnapshots
        self.activityRecordSnapshots = activityRecordSnapshots
        self.isDirty = isDirty
        self.isDeleted = isDeleted
    }
}
