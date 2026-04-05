import CoreData
import CoreStorage
import Domain
import XCTest
@testable import CommonSync

final class CategorySyncRepositoryTests: XCTestCase {
    func testApplyRemoteReplacesLocalWhenServerVersionIsGreater() async throws {
        let coreDataStack = try makeInMemoryCoreDataStack()
        let repository = CategorySyncRepository(coreDataStack: coreDataStack)
        let localID = UUID()

        try await coreDataStack.performBackgroundTransaction { context in
            let object = CategoryMO(context: context)
            object.localID = localID
            object.remoteID = 5
            object.lastModifiedVersion = 2
            object.baseName = "Local"
            object.code = .work
            object.isDirty = true
            object.syncDeleted = false
        }

        let applied = try await repository.applyRemote([
            RemoteCategoryDTO(
                id: 5,
                lastModifiedVersion: 3,
                name: "Server",
                code: .sleep,
                deleted: true
            )
        ])

        XCTAssertEqual(applied, 1)

        let stored = try await coreDataStack.performBackgroundTask { context in
            let request = CategoryMO.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "remoteID == 5")
            let object = try XCTUnwrap(context.fetch(request).first)
            return (
                object.localID,
                object.baseName,
                object.code,
                object.lastModifiedVersionValue,
                object.isDirty,
                object.syncDeleted
            )
        }

        XCTAssertEqual(stored.0, localID)
        XCTAssertEqual(stored.1, "Server")
        XCTAssertEqual(stored.2, .sleep)
        XCTAssertEqual(stored.3, 3)
        XCTAssertFalse(stored.4)
        XCTAssertTrue(stored.5)
    }

    func testApplyRemoteKeepsLocalWhenVersionsAreEqual() async throws {
        let coreDataStack = try makeInMemoryCoreDataStack()
        let repository = CategorySyncRepository(coreDataStack: coreDataStack)

        try await coreDataStack.performBackgroundTransaction { context in
            let object = CategoryMO(context: context)
            object.localID = UUID()
            object.remoteID = 5
            object.lastModifiedVersion = 3
            object.baseName = "Local"
            object.code = .work
            object.isDirty = true
            object.syncDeleted = false
        }

        let applied = try await repository.applyRemote([
            RemoteCategoryDTO(
                id: 5,
                lastModifiedVersion: 3,
                name: "Server",
                code: .sleep,
                deleted: true
            )
        ])

        XCTAssertEqual(applied, 0)

        let stored = try await coreDataStack.performBackgroundTask { context in
            let request = CategoryMO.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "remoteID == 5")
            let object = try XCTUnwrap(context.fetch(request).first)
            return (
                object.baseName,
                object.code,
                object.isDirty,
                object.syncDeleted
            )
        }

        XCTAssertEqual(stored.0, "Local")
        XCTAssertEqual(stored.1, .work)
        XCTAssertTrue(stored.2)
        XCTAssertFalse(stored.3)
    }
}
