import CoreAuth
import CoreNetwork
import Domain
import Foundation

public actor DefaultUserProfileService: UserProfileServiceProtocol {
    private let profileService: NetworkProfileService
    private let sessionsService: NetworkSessionsService
    private let cacheStore: UserProfileCacheStore

    init(
        profileService: NetworkProfileService,
        sessionsService: NetworkSessionsService,
        cacheStore: UserProfileCacheStore
    ) {
        self.profileService = profileService
        self.sessionsService = sessionsService
        self.cacheStore = cacheStore
    }

    nonisolated public func cachedUser() -> User? {
        cacheStore.loadUser()
    }

    nonisolated public func cachedSessions() -> UserSessions? {
        cacheStore.loadSessions()
    }

    public func fetchUser() async throws -> User {
        do {
            let response = try await profileService.fetchUser()
            let snapshotVersion = cacheStore.loadUser()?.snapshotVersion ?? .zero
            let user = makeUser(from: response, snapshotVersion: snapshotVersion)
            cacheStore.saveUser(user)
            return user
        } catch {
            if shouldFallbackToCache(for: error), let cachedUser = cacheStore.loadUser() {
                return cachedUser
            }
            throw error
        }
    }

    public func updateProfile(name: String) async throws -> User {
        let response = try await profileService.updateProfile(name: name)
        let snapshotVersion = cacheStore.loadUser()?.snapshotVersion ?? .zero
        let user = makeUser(from: response, snapshotVersion: snapshotVersion)
        cacheStore.saveUser(user)
        return user
    }

    public func deleteUser() async throws {
        try await profileService.deleteUser()
    }

    public func fetchSessions() async throws -> UserSessions {
        do {
            let sessions = try await sessionsService.fetchSessions()
            cacheStore.saveSessions(sessions)
            return sessions
        } catch {
            if shouldFallbackToCache(for: error), let cachedSessions = cacheStore.loadSessions() {
                return cachedSessions
            }
            throw error
        }
    }

    public func logoutDevice(sessionID: Int64) async throws {
        try await sessionsService.logoutDevice(sessionID: sessionID)

        guard let cachedSessions = cacheStore.loadSessions() else {
            return
        }

        let updatedSessions = UserSessions(
            currentSessionID: cachedSessions.currentSessionID,
            sessions: cachedSessions.sessions.filter { $0.sessionID != sessionID }
        )
        cacheStore.saveSessions(updatedSessions)
    }

    public func logoutOtherDevices() async throws {
        try await sessionsService.logoutOtherDevices()

        guard let cachedSessions = cacheStore.loadSessions() else {
            return
        }

        let updatedSessions = UserSessions(
            currentSessionID: cachedSessions.currentSessionID,
            sessions: cachedSessions.sessions.filter { $0.sessionID == cachedSessions.currentSessionID }
        )
        cacheStore.saveSessions(updatedSessions)
    }

    public func currentSnapshotVersion() async -> SnapshotVersion {
        cacheStore.loadUser()?.snapshotVersion ?? .zero
    }

    public func updateSnapshotVersion(_ snapshotVersion: SnapshotVersion) async {
        let currentUser = cacheStore.loadUser()
        let user = User(
            firstName: currentUser?.firstName,
            email: currentUser?.email,
            snapshotVersion: snapshotVersion
        )
        cacheStore.saveUser(user)
    }

    public func clearUser() async {
        cacheStore.clearUser()
    }

    public func clearSessions() async {
        cacheStore.clearSessions()
    }

    private func shouldFallbackToCache(for error: Error) -> Bool {
        guard let networkError = error as? NetworkError else {
            return false
        }

        if case .transportError = networkError {
            return true
        }

        return false
    }

    private func makeUser(
        from response: UserResponseDTO,
        snapshotVersion: SnapshotVersion
    ) -> User {
        User(
            firstName: response.firstName,
            email: response.email,
            snapshotVersion: snapshotVersion
        )
    }
}
