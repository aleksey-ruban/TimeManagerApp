import Foundation

public struct Category: Sendable, Hashable {
    public let localID: UUID
    public let remoteID: Int64?
    public let lastModifiedVersion: Int64?
    public let baseName: String
    public let code: CategoryCode?
    public let isDirty: Bool
    public let isDeleted: Bool

    public init(
        localID: UUID,
        remoteID: Int64?,
        lastModifiedVersion: Int64?,
        baseName: String,
        code: CategoryCode?,
        isDirty: Bool,
        isDeleted: Bool
    ) {
        self.localID = localID
        self.remoteID = remoteID
        self.lastModifiedVersion = lastModifiedVersion
        self.baseName = baseName
        self.code = code
        self.isDirty = isDirty
        self.isDeleted = isDeleted
    }
}
