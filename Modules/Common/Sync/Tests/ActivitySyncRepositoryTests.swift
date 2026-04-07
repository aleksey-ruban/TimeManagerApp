import CoreData
import CoreStorage
import Domain
import XCTest
@testable import CommonSync

final class ActivitySyncRepositoryTests: XCTestCase {
    func testApplyRemotePreservesDirtyDeletedActivityAndHydratesServerVersion() async throws {
        let coreDataStack = try makeInMemoryCoreDataStack()
        let repository = ActivitySyncRepository(coreDataStack: coreDataStack)
        let localID = UUID()

        try await coreDataStack.performBackgroundTransaction { context in
            let activity = ActivityMO(context: context)
            activity.localID = localID
            activity.remoteID = 10
            activity.lastModifiedVersion = nil
            activity.name = "Local Activity"
            activity.iconName = "figure.run"
            activity.colorRawValue = ActivityColor.teal.rawValue
            activity.isDirty = true
            activity.syncDeleted = true
        }

        let applied = try await repository.applyRemote([
            RemoteActivityDTO(
                id: 10,
                lastModifiedVersion: 14,
                name: "Server Activity",
                categoryId: nil,
                icon: "figure.run",
                iconColor: "TEAL",
                variations: [],
                deleted: false
            )
        ])

        XCTAssertEqual(applied, 1)

        let stored = try await coreDataStack.performBackgroundTask { context in
            let request = ActivityMO.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "localID == %@", localID as CVarArg)

            let activity = try XCTUnwrap(context.fetch(request).first)
            return (
                activity.remoteIDValue,
                activity.lastModifiedVersionValue,
                activity.isDirty,
                activity.syncDeleted
            )
        }

        XCTAssertEqual(stored.0, 10)
        XCTAssertEqual(stored.1, 14)
        XCTAssertTrue(stored.2)
        XCTAssertTrue(stored.3)

        let dirty = try await repository.fetchDirty()
        XCTAssertEqual(dirty.count, 1)
        XCTAssertEqual(dirty.first?.remoteID, 10)
        XCTAssertEqual(dirty.first?.lastModifiedVersion, 14)
        XCTAssertTrue(dirty.first?.isDeleted == true)
    }

    func testApplyRemoteReplacesVariationsAndDeletesOldOnes() async throws {
        let coreDataStack = try makeInMemoryCoreDataStack()
        let repository = ActivitySyncRepository(coreDataStack: coreDataStack)
        let preservedVariationLocalID = UUID()

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
            oldVariation.localID = preservedVariationLocalID
            oldVariation.remoteID = 200
            oldVariation.value = "Preserved"
            oldVariation.position = 0
            oldVariation.syncDeleted = false
            oldVariation.activity = activity

            let duplicateVariation = ActivityVariationMO(context: context)
            duplicateVariation.localID = UUID()
            duplicateVariation.remoteID = 200
            duplicateVariation.value = "Duplicate"
            duplicateVariation.position = 1
            duplicateVariation.syncDeleted = false
            duplicateVariation.activity = activity

            activity.variations = [oldVariation, duplicateVariation]
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
                    .map { ($0.localID, $0.remoteIDValue, $0.value, $0.syncDeleted) }
            )
        }

        XCTAssertEqual(stored.0, "Server Activity")
        XCTAssertEqual(stored.1, "new.icon")
        XCTAssertEqual(stored.2, .green)
        XCTAssertFalse(stored.3)
        XCTAssertEqual(stored.4.count, 2)
        XCTAssertEqual(stored.4.map(\.1), [200, 201])
        XCTAssertEqual(stored.4.map(\.2), ["First", "Second"])
        XCTAssertEqual(stored.4.map(\.3), [false, true])
        XCTAssertEqual(stored.4.first?.0, preservedVariationLocalID)
    }
}
