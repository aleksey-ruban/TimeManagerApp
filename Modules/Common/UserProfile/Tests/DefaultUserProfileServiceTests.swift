import CoreNetwork
import Domain
import XCTest
@testable import CommonUserProfile

final class DefaultUserProfileServiceTests: XCTestCase {
    func testFetchUserReturnsRemoteUserAndPreservesSnapshotVersionFromCache() async throws {
        let defaults = makeTestDefaults()
        let cacheStore = UserProfileCacheStore(defaults: defaults)
        await cacheStore.saveUser(
            User(
                firstName: "Cached",
                email: "cached@example.com",
                snapshotVersion: SnapshotVersion(Int64(42))
            )
        )

        let service = makeService(
            profileResult: .success(
                Data(#"{"firstName":"Aleksey","email":"alekseyruban555@gmail.com"}"#.utf8)
            ),
            sessionsResult: .success(Data(#"{"currentSessionId":4,"sessions":[]}"#.utf8)),
            defaults: defaults
        )

        let user = try await service.fetchUser()

        XCTAssertEqual(user.firstName, "Aleksey")
        XCTAssertEqual(user.email, "alekseyruban555@gmail.com")
        XCTAssertEqual(user.snapshotVersion, SnapshotVersion(Int64(42)))
    }

    func testFetchUserReturnsCachedUserWhenNetworkIsOffline() async throws {
        let defaults = makeTestDefaults()
        let cacheStore = UserProfileCacheStore(defaults: defaults)
        let cachedUser = User(
            firstName: "Cached",
            email: "cached@example.com",
            snapshotVersion: SnapshotVersion(Int64(7))
        )
        await cacheStore.saveUser(cachedUser)

        let service = makeService(
            profileResult: .failure(NetworkError.transportError("offline", isRetryable: true)),
            sessionsResult: .success(Data(#"{"currentSessionId":4,"sessions":[]}"#.utf8)),
            defaults: defaults
        )

        let user = try await service.fetchUser()

        XCTAssertEqual(user, cachedUser)
    }

    func testFetchSessionsReturnsCachedSessionsWhenNetworkIsOffline() async throws {
        let defaults = makeTestDefaults()
        let cacheStore = UserProfileCacheStore(defaults: defaults)
        let cachedSessions = UserSessions(
            currentSessionID: 4,
            sessions: [
                UserSession(
                    sessionID: 4,
                    deviceModel: "iPhone 16 Pro Black",
                    createdAt: Date(timeIntervalSince1970: 100),
                    lastUsedAt: Date(timeIntervalSince1970: 200)
                )
            ]
        )
        await cacheStore.saveSessions(cachedSessions)

        let service = makeService(
            profileResult: .success(
                Data(#"{"firstName":"Aleksey","email":"alekseyruban555@gmail.com"}"#.utf8)
            ),
            sessionsResult: .failure(NetworkError.transportError("offline", isRetryable: true)),
            defaults: defaults
        )

        let sessions = try await service.fetchSessions()

        XCTAssertEqual(sessions, cachedSessions)
    }

    func testUpdateSnapshotVersionOverridesCachedUserSnapshotVersion() async throws {
        let defaults = makeTestDefaults()
        let cacheStore = UserProfileCacheStore(defaults: defaults)
        await cacheStore.saveUser(
            User(
                firstName: "Aleksey",
                email: "alekseyruban555@gmail.com",
                snapshotVersion: .zero
            )
        )
        let service = makeService(
            profileResult: .success(
                Data(#"{"firstName":"Aleksey","email":"alekseyruban555@gmail.com"}"#.utf8)
            ),
            sessionsResult: .success(Data(#"{"currentSessionId":4,"sessions":[]}"#.utf8)),
            defaults: defaults
        )

        await service.updateSnapshotVersion(SnapshotVersion(Int64(99)))

        let version = await service.currentSnapshotVersion()
        let cachedUser = await cacheStore.loadUser()

        XCTAssertEqual(version, SnapshotVersion(Int64(99)))
        XCTAssertEqual(cachedUser?.snapshotVersion, SnapshotVersion(Int64(99)))
        XCTAssertEqual(cachedUser?.firstName, "Aleksey")
    }

    func testClearUserRemovesCachedUserAndResetsSnapshotVersion() async throws {
        let defaults = makeTestDefaults()
        let cacheStore = UserProfileCacheStore(defaults: defaults)
        await cacheStore.saveUser(
            User(
                firstName: "Aleksey",
                email: "alekseyruban555@gmail.com",
                snapshotVersion: SnapshotVersion(Int64(10))
            )
        )
        let service = makeService(
            profileResult: .success(
                Data(#"{"firstName":"Aleksey","email":"alekseyruban555@gmail.com"}"#.utf8)
            ),
            sessionsResult: .success(Data(#"{"currentSessionId":4,"sessions":[]}"#.utf8)),
            defaults: defaults
        )

        await service.clearUser()

        let cachedUser = await cacheStore.loadUser()
        let snapshotVersion = await service.currentSnapshotVersion()

        XCTAssertNil(cachedUser)
        XCTAssertEqual(snapshotVersion, .zero)
    }

    func testClearSessionsRemovesCachedSessions() async throws {
        let defaults = makeTestDefaults()
        let cacheStore = UserProfileCacheStore(defaults: defaults)
        await cacheStore.saveSessions(
            UserSessions(
                currentSessionID: 4,
                sessions: [
                    UserSession(
                        sessionID: 4,
                        deviceModel: "iPhone 16 Pro Black",
                        createdAt: Date(timeIntervalSince1970: 100),
                        lastUsedAt: Date(timeIntervalSince1970: 200)
                    )
                ]
            )
        )
        let service = makeService(
            profileResult: .success(
                Data(#"{"firstName":"Aleksey","email":"alekseyruban555@gmail.com"}"#.utf8)
            ),
            sessionsResult: .success(Data(#"{"currentSessionId":4,"sessions":[]}"#.utf8)),
            defaults: defaults
        )

        await service.clearSessions()

        let cachedSessions = await cacheStore.loadSessions()

        XCTAssertNil(cachedSessions)
    }

    func testFetchSessionsReplacesPreviouslyCachedSessions() async throws {
        let defaults = makeTestDefaults()
        let cacheStore = UserProfileCacheStore(defaults: defaults)
        await cacheStore.saveSessions(
            UserSessions(
                currentSessionID: 1,
                sessions: [
                    UserSession(
                        sessionID: 1,
                        deviceModel: "Old Device",
                        createdAt: Date(timeIntervalSince1970: 10),
                        lastUsedAt: Date(timeIntervalSince1970: 20)
                    ),
                    UserSession(
                        sessionID: 2,
                        deviceModel: "Older Device",
                        createdAt: Date(timeIntervalSince1970: 30),
                        lastUsedAt: Date(timeIntervalSince1970: 40)
                    )
                ]
            )
        )
        let response = """
        {
            "currentSessionId": 4,
            "sessions": [
                {
                    "sessionId": 4,
                    "deviceModel": "iPhone 16 Pro Black",
                    "createdAt": "2026-04-05T13:35:38.795116Z",
                    "lastUsedAt": "2026-04-05T13:35:51.572166Z"
                }
            ]
        }
        """
        let service = makeService(
            profileResult: .success(
                Data(#"{"firstName":"Aleksey","email":"alekseyruban555@gmail.com"}"#.utf8)
            ),
            sessionsResult: .success(Data(response.utf8)),
            defaults: defaults
        )

        let sessions = try await service.fetchSessions()
        let cachedSessions = await cacheStore.loadSessions()

        XCTAssertEqual(sessions.currentSessionID, 4)
        XCTAssertEqual(sessions.sessions.count, 1)
        XCTAssertEqual(sessions.sessions.first?.sessionID, 4)
        XCTAssertEqual(cachedSessions, sessions)
    }

    private func makeService(
        profileResult: Result<Data, Error>,
        sessionsResult: Result<Data, Error>,
        defaults: UserDefaults
    ) -> DefaultUserProfileService {
        let profileExecutor = NetworkExecutorStub(result: profileResult)
        let sessionsExecutor = NetworkExecutorStub(result: sessionsResult)

        return DefaultUserProfileService(
            profileService: NetworkProfileService(
                executorFactory: NetworkExecutorFactoryStub(executor: profileExecutor),
                configuration: UserProfileAPIConfiguration(baseURL: URL(string: "https://example.com")!)
            ),
            sessionsService: NetworkSessionsService(
                executorFactory: NetworkExecutorFactoryStub(executor: sessionsExecutor),
                configuration: UserProfileAPIConfiguration(baseURL: URL(string: "https://example.com")!)
            ),
            cacheStore: UserProfileCacheStore(defaults: defaults)
        )
    }
}
