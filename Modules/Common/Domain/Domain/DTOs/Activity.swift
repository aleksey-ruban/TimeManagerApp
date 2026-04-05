import Foundation

public struct Activity: Sendable, Hashable {
    public let localID: UUID
    public let remoteID: Int64?
    public let lastModifiedVersion: Int64?
    public let name: String
    public let categoryLocalID: UUID?
    public let categoryRemoteID: Int64?
    public let iconName: String
    public let color: ActivityColor
    public let variations: [ActivityVariation]
    public let isDirty: Bool
    public let isDeleted: Bool

    public init(
        localID: UUID,
        remoteID: Int64?,
        lastModifiedVersion: Int64?,
        name: String,
        categoryLocalID: UUID?,
        categoryRemoteID: Int64?,
        iconName: String,
        color: ActivityColor,
        variations: [ActivityVariation],
        isDirty: Bool,
        isDeleted: Bool
    ) {
        self.localID = localID
        self.remoteID = remoteID
        self.lastModifiedVersion = lastModifiedVersion
        self.name = name
        self.categoryLocalID = categoryLocalID
        self.categoryRemoteID = categoryRemoteID
        self.iconName = iconName
        self.color = color
        self.variations = variations
        self.isDirty = isDirty
        self.isDeleted = isDeleted
    }
}
