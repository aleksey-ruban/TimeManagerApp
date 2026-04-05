import CoreData
import CoreStorage
import Domain
import XCTest
@testable import CommonSync

final class ActivitySyncRepositoryTests: XCTestCase {
    func testApplyRemoteReplacesVariationsAndDeletesOldOnes() async throws {
        let coreDataStack = try makeInMemoryCoreDataStack()
        let repository = ActivitySyncRepository(coreDataStack: coreDataStack)

        try await coreDataStack.performBackgroundTransaction { context in
            let category = CategoryMO(context: context)
            category.localID = UUID()
            category.remoteID = 1
            category.lastModifiedVersion = 1
            category.baseName = "Category"
            category.isDirty = false
            category.syncDeleted = false

            let activity = ActivityMO(context: context)
            activity.localID = UUID()
            activity.remoteID = 10
            activity.lastModifiedVersion = 1
            activity.name = "Local Activity"
            activity.iconName = "old.icon"
            activity.colorRawValue = ActivityColor.red.rawValue
            activity.isDirty = true
            activity.syncDeleted = false
            activity.category = category

            let oldVariation = ActivityVariationMO(context: context)
            oldVariation.localID = UUID()
            oldVariation.remoteID = 100
            oldVariation.value = "Old"
            oldVariation.position = 0
            oldVariation.syncDeleted = false
            oldVariation.activity = activity

            activity.variations = [oldVariation]
        }

        let applied = try await repository.applyRemote([
            RemoteActivityDTO(
                id: 10,
                lastModifiedVersion: 2,
                name: "Server Activity",
                categoryId: 1,
                icon: "new.icon",
                iconColor: "GREEN",
                variations: [
                    RemoteVariationDTO(id: 200, position: 0, value: "First", deleted: false),
                    RemoteVariationDTO(id: 201, position: 1, value: "Second", deleted: true),
                ],
                deleted: false
            )
        ])

        XCTAssertEqual(applied, 1)

        let stored = try await coreDataStack.performBackgroundTask { context in
            let activityRequest = ActivityMO.fetchRequest()
            activityRequest.fetchLimit = 1
            activityRequest.predicate = NSPredicate(format: "remoteID == 10")

            let variationRequest = ActivityVariationMO.fetchRequest()
            let activity = try XCTUnwrap(context.fetch(activityRequest).first)
            let variations = try context.fetch(variationRequest)

            return (
                activity.name,
                activity.iconName,
                activity.color,
                activity.isDirty,
                variations
                    .sorted { $0.position < $1.position }
                    .map { ($0.remoteIDValue, $0.value, $0.syncDeleted) }
            )
        }

        XCTAssertEqual(stored.0, "Server Activity")
        XCTAssertEqual(stored.1, "new.icon")
        XCTAssertEqual(stored.2, .green)
        XCTAssertFalse(stored.3)
        XCTAssertEqual(stored.4.count, 2)
        XCTAssertEqual(stored.4.map(\.0), [200, 201])
        XCTAssertEqual(stored.4.map(\.1), ["First", "Second"])
        XCTAssertEqual(stored.4.map(\.2), [false, true])
    }
}
