import Domain
import Foundation

public protocol UserProfileServiceProtocol: Sendable {
    func fetchUser() async throws -> User
    func fetchSessions() async throws -> UserSessions
    func currentSnapshotVersion() async -> SnapshotVersion
    func updateSnapshotVersion(_ snapshotVersion: SnapshotVersion) async
    func clearUser() async
    func clearSessions() async
}
