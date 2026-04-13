public struct ActivityVariationSnapshot: Sendable, Hashable {
    public let remoteID: Int64?
    public let globalActivityVariationID: Int64?
    public let value: String

    public init(
        remoteID: Int64?,
        globalActivityVariationID: Int64?,
        value: String
    ) {
        self.remoteID = remoteID
        self.globalActivityVariationID = globalActivityVariationID
        self.value = value
    }
}
