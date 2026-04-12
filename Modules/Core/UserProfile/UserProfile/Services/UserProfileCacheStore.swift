import CoreAuth
import Domain
import Foundation

final class UserProfileCacheStore: @unchecked Sendable {
    private enum CacheKey {
        static let user = "common.userProfile.user"
        static let sessions = "common.userProfile.sessions"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSLock()

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func loadUser() -> User? {
        withLock {
            loadValue(User.self, forKey: CacheKey.user)
        }
    }

    func saveUser(_ user: User) {
        withLock {
            saveValue(user, forKey: CacheKey.user)
        }
    }

    func clearUser() {
        withLock {
            defaults.removeObject(forKey: CacheKey.user)
        }
    }

    func loadSessions() -> UserSessions? {
        withLock {
            loadValue(UserSessions.self, forKey: CacheKey.sessions)
        }
    }

    func saveSessions(_ sessions: UserSessions) {
        withLock {
            defaults.removeObject(forKey: CacheKey.sessions)
            saveValue(sessions, forKey: CacheKey.sessions)
        }
    }

    func clearSessions() {
        withLock {
            defaults.removeObject(forKey: CacheKey.sessions)
        }
    }

    private func loadValue<Value: Decodable>(
        _ type: Value.Type,
        forKey key: String
    ) -> Value? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        return try? decoder.decode(Value.self, from: data)
    }

    private func saveValue<Value: Encodable>(_ value: Value, forKey key: String) {
        guard let data = try? encoder.encode(value) else {
            return
        }

        defaults.set(data, forKey: key)
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
