public struct ActivitySnapshot: Sendable, Hashable {
    public let remoteID: Int64?
    public let globalActivityID: Int64?
    public let name: String
    public let categorySnapshotRemoteID: Int64?
    public let iconName: String
    public let color: ActivityColor
    public let variations: [ActivityVariationSnapshot]

    public init(
        remoteID: Int64?,
        globalActivityID: Int64?,
        name: String,
        categorySnapshotRemoteID: Int64?,
        iconName: String,
        color: ActivityColor,
        variations: [ActivityVariationSnapshot]
    ) {
        self.remoteID = remoteID
        self.globalActivityID = globalActivityID
        self.name = name
        self.categorySnapshotRemoteID = categorySnapshotRemoteID
        self.iconName = iconName
        self.color = color
        self.variations = variations
    }
}
