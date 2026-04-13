import CoreSessionCleanup
import CoreUserProfile
import CoreAuth
import Domain
import Foundation

@MainActor
protocol SettingsFeatureServiceProtocol: AnyObject {
    func cachedUser() -> User?
    func cachedSessions() -> UserSessions?
    func fetchUser() async throws -> User
    func updateProfile(name: String) async throws -> User
    func fetchSessions() async throws -> UserSessions
    func logoutDevice(sessionID: Int64) async throws -> UserSessions
    func logoutOtherDevices() async throws -> UserSessions
    func logoutCurrentDevice(sessionID: Int64) async throws
    func deleteAccount() async throws
}

@MainActor
final class SettingsFeatureService: SettingsFeatureServiceProtocol {
    private let userProfileService: UserProfileServiceProtocol
    private let authFeatureService: AuthFeatureServiceProtocol
    private let sessionCleanupService: SessionCleanupServiceProtocol

    init(
        userProfileService: UserProfileServiceProtocol,
        authFeatureService: AuthFeatureServiceProtocol,
        sessionCleanupService: SessionCleanupServiceProtocol
    ) {
        self.userProfileService = userProfileService
        self.authFeatureService = authFeatureService
        self.sessionCleanupService = sessionCleanupService
    }

    func cachedUser() -> User? {
        userProfileService.cachedUser()
    }

    func cachedSessions() -> UserSessions? {
        userProfileService.cachedSessions()
    }

    func fetchUser() async throws -> User {
        try await userProfileService.fetchUser()
    }

    func updateProfile(name: String) async throws -> User {
        try await userProfileService.updateProfile(name: name)
    }

    func fetchSessions() async throws -> UserSessions {
        try await userProfileService.fetchSessions()
    }

    func logoutDevice(sessionID: Int64) async throws -> UserSessions {
        try await userProfileService.logoutDevice(sessionID: sessionID)
        return try await userProfileService.fetchSessions()
    }

    func logoutOtherDevices() async throws -> UserSessions {
        try await userProfileService.logoutOtherDevices()
        return try await userProfileService.fetchSessions()
    }

    func logoutCurrentDevice(sessionID: Int64) async throws {
        try await userProfileService.logoutDevice(sessionID: sessionID)
        try await authFeatureService.logout()
        try await sessionCleanupService.clearLocalSessionArtifacts()
    }

    func deleteAccount() async throws {
        try await userProfileService.deleteUser()
        try await authFeatureService.logout()
        try await sessionCleanupService.clearLocalSessionArtifacts()
    }
}
