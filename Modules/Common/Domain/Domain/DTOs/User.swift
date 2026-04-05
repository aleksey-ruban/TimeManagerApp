import Foundation

public struct User: Sendable, Codable, Hashable {
    public let firstName: String?
    public let email: String?
    public let snapshotVersion: SnapshotVersion

    public init(
        firstName: String?,
        email: String?,
        snapshotVersion: SnapshotVersion
    ) {
        self.firstName = firstName
        self.email = email
        self.snapshotVersion = snapshotVersion
    }
}
