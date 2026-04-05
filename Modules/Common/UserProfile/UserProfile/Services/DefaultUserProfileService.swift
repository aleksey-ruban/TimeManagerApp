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

    public func fetchUser() async throws -> User {
        do {
            let response = try await profileService.fetchUser()
            let snapshotVersion = await cacheStore.loadUser()?.snapshotVersion ?? .zero
            let user = User(
                firstName: response.firstName,
                email: response.email,
                snapshotVersion: snapshotVersion
            )
            await cacheStore.saveUser(user)
            return user
        } catch {
            if shouldFallbackToCache(for: error), let cachedUser = await cacheStore.loadUser() {
                return cachedUser
            }
            throw error
        }
    }

    public func fetchSessions() async throws -> UserSessions {
        do {
            let sessions = try await sessionsService.fetchSessions()
            await cacheStore.saveSessions(sessions)
            return sessions
        } catch {
            if shouldFallbackToCache(for: error), let cachedSessions = await cacheStore.loadSessions() {
                return cachedSessions
            }
            throw error
        }
    }

    public func currentSnapshotVersion() async -> SnapshotVersion {
        await cacheStore.loadUser()?.snapshotVersion ?? .zero
    }

    public func updateSnapshotVersion(_ snapshotVersion: SnapshotVersion) async {
        let currentUser = await cacheStore.loadUser()
        let user = User(
            firstName: currentUser?.firstName,
            email: currentUser?.email,
            snapshotVersion: snapshotVersion
        )
        await cacheStore.saveUser(user)
    }

    public func clearUser() async {
        await cacheStore.clearUser()
    }

    public func clearSessions() async {
        await cacheStore.clearSessions()
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
}
