import CoreStorage
import CoreSync
import Domain
import Foundation
import XCTest
@testable import CommonSync

final class CategoriesPushStageTests: XCTestCase {
    func testExecuteAcknowledgesSuccessfulPush() async throws {
        let coreDataStack = try makeInMemoryCoreDataStack()
        let repository = CategorySyncRepository(coreDataStack: coreDataStack)
        let localID = UUID()

        try await coreDataStack.performBackgroundTransaction { context in
            let object = CategoryMO(context: context)
            object.localID = localID
            object.baseName = "Gym"
            object.isDirty = true
            object.syncDeleted = false
        }

        let remoteAPI = SyncRemoteAPIStub(
            pushCategoriesHandler: { categories in
                XCTAssertEqual(categories.count, 1)
                XCTAssertEqual(categories.first?.localID, localID)
                return [
                    SyncPushResultDTO(
                        objectType: .category,
                        operation: .create,
                        localId: localID,
                        serverId: 5,
                        status: "OK"
                    )
                ]
            }
        )
        let stage = CategoriesPushStage(repository: repository, remoteAPI: remoteAPI)

        let updated = try await stage.execute(
            context: SyncExecutionContext(trigger: .manual, startedAt: Date())
        )

        XCTAssertEqual(updated, 1)

        let stored = try await coreDataStack.performBackgroundTask { context in
            let request = CategoryMO.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "localID == %@", localID as CVarArg)
            let object = try XCTUnwrap(context.fetch(request).first)
            return (object.remoteIDValue, object.isDirty)
        }

        XCTAssertEqual(stored.0, 5)
        XCTAssertFalse(stored.1)
    }

    func testExecuteThrowsWhenServerReturnsDifferentResultCount() async throws {
        let coreDataStack = try makeInMemoryCoreDataStack()
        let repository = CategorySyncRepository(coreDataStack: coreDataStack)

        try await coreDataStack.performBackgroundTransaction { context in
            for name in ["Gym", "Sleep"] {
                let object = CategoryMO(context: context)
                object.localID = UUID()
                object.baseName = name
                object.isDirty = true
                object.syncDeleted = false
            }
        }

        let remoteAPI = SyncRemoteAPIStub(
            pushCategoriesHandler: { categories in
                XCTAssertEqual(categories.count, 2)
                return [
                    SyncPushResultDTO(
                        objectType: .category,
                        operation: .create,
                        localId: categories[0].localID,
                        serverId: 5,
                        status: "OK"
                    )
                ]
            }
        )
        let stage = CategoriesPushStage(repository: repository, remoteAPI: remoteAPI)

        do {
            _ = try await stage.execute(
                context: SyncExecutionContext(trigger: .manual, startedAt: Date())
            )
            XCTFail("Expected responseCountMismatch")
        } catch let error as CommonSyncError {
            guard case let .responseCountMismatch(stage, expected, received) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(stage, CommonSyncStageIDs.categories.rawValue)
            XCTAssertEqual(expected, 2)
            XCTAssertEqual(received, 1)
        }
    }
}
