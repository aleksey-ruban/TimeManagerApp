import CoreAuth
import CoreStorage
import CoreSync
import CoreUserProfile
import Domain
import Foundation
import XCTest
@testable import CommonSync

final class ChronometriesPushStageTests: XCTestCase {
    func testExecuteUsesCurrentAccountSnapshotVersionForChronometryFinish() async throws {
        let coreDataStack = try makeInMemoryCoreDataStack()
        let repository = ChronometrySyncRepository(coreDataStack: coreDataStack)
        let localID = UUID()

        try await coreDataStack.performBackgroundTransaction { context in
            let object = ChronometryMO(context: context)
            object.localID = localID
            object.remoteID = 11
            object.lastModifiedVersion = 7
            object.startDate = Date(timeIntervalSince1970: 1_744_070_400)
            object.endDate = Date(timeIntervalSince1970: 1_744_588_800)
            object.isFinished = true
            object.timeZone = "Europe/Moscow"
            object.isDirty = true
            object.syncDeleted = false
        }

        let userProfileService = UserProfileServiceStub(snapshotVersion: SnapshotVersion(Int64(51)))
        let remoteAPI = SyncRemoteAPIStub(
            pushChronometriesHandler: { chronometries, accountSnapshotVersion in
                XCTAssertEqual(chronometries.count, 1)
                XCTAssertEqual(chronometries.first?.localID, localID)
                XCTAssertEqual(chronometries.first?.lastModifiedVersion, 7)
                XCTAssertEqual(accountSnapshotVersion, SnapshotVersion(Int64(51)))
                return [
                    SyncPushResultDTO(
                        objectType: .chronometrySnapshot,
                        operation: .update,
                        localId: localID,
                        serverId: 11,
                        lastModifiedVersion: 12,
                        status: "OK",
                        errorCode: nil,
                        errorMessage: nil
                    )
                ]
            }
        )
        let stage = ChronometriesPushStage(
            repository: repository,
            remoteAPI: remoteAPI,
            userProfileService: userProfileService
        )

        let updated = try await stage.execute(
            context: SyncExecutionContext(trigger: .manual, startedAt: Date())
        )

        XCTAssertEqual(updated, 1)
    }
}

private actor UserProfileServiceStub: UserProfileServiceProtocol {
    let snapshotVersion: SnapshotVersion

    init(snapshotVersion: SnapshotVersion) {
        self.snapshotVersion = snapshotVersion
    }

    func fetchUser() async throws -> User {
        User(firstName: nil, email: nil, snapshotVersion: snapshotVersion)
    }

    func updateProfile(name: String) async throws -> User {
        User(firstName: name, email: nil, snapshotVersion: snapshotVersion)
    }

    func deleteUser() async throws {}

    func fetchSessions() async throws -> UserSessions {
        UserSessions(currentSessionID: 0, sessions: [])
    }

    func logoutDevice(sessionID: Int64) async throws {}

    func logoutOtherDevices() async throws {}

    func currentSnapshotVersion() async -> SnapshotVersion {
        snapshotVersion
    }

    func updateSnapshotVersion(_ snapshotVersion: SnapshotVersion) async {}

    func clearUser() async {}

    func clearSessions() async {}
}
