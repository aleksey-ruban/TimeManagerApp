public struct CategorySnapshot: Sendable, Hashable {
    public let remoteID: Int64?
    public let globalCategoryID: Int64?
    public let baseName: String
    public let code: CategoryCode?

    public init(
        remoteID: Int64?,
        globalCategoryID: Int64?,
        baseName: String,
        code: CategoryCode?
    ) {
        self.remoteID = remoteID
        self.globalCategoryID = globalCategoryID
        self.baseName = baseName
        self.code = code
    }
}
