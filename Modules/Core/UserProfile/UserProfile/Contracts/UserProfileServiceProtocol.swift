import CoreAuth
import CoreSessionCleanup
import Domain
import Foundation

public protocol UserProfileServiceProtocol: SessionCleanupUserArtifactsStoreProtocol, Sendable {
    func cachedUser() -> User?
    func cachedSessions() -> UserSessions?
    func fetchUser() async throws -> User
    func updateProfile(name: String) async throws -> User
    func deleteUser() async throws
    func fetchSessions() async throws -> UserSessions
    func logoutDevice(sessionID: Int64) async throws
    func logoutOtherDevices() async throws
    func currentSnapshotVersion() async -> SnapshotVersion
    func updateSnapshotVersion(_ snapshotVersion: SnapshotVersion) async
    func clearUser() async
    func clearSessions() async
}
