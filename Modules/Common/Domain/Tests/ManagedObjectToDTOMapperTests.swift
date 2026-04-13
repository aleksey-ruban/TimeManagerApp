import CoreStorage
import Domain
import XCTest

final class ManagedObjectToDTOMapperTests: XCTestCase {
    func testCategoryActivityAndRecordMapToDTO() async throws {
        let coreDataStack = try makeInMemoryDomainCoreDataStack()
        let ids = (
            category: UUID(),
            activity: UUID(),
            variationA: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!,
            variationB: UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")!,
            record: UUID()
        )
        let start = Date(timeIntervalSince1970: 100)
        let end = Date(timeIntervalSince1970: 200)

        let result = try await coreDataStack.performBackgroundTransaction { context in
            let category = CategoryMO(context: context)
            category.localID = ids.category
            category.remoteID = 1
            category.lastModifiedVersion = 2
            category.baseName = "Category"
            category.code = .work
            category.isDirty = true
            category.syncDeleted = false

            let activity = ActivityMO(context: context)
            activity.localID = ids.activity
            activity.remoteID = 3
            activity.lastModifiedVersion = 4
            activity.name = "Activity"
            activity.iconName = "figure.run"
            activity.color = .green
            activity.isDirty = false
            activity.syncDeleted = true
            activity.category = category

            let variationLater = ActivityVariationMO(context: context)
            variationLater.localID = ids.variationB
            variationLater.remoteID = 20
            variationLater.value = "Later"
            variationLater.position = 2
            variationLater.syncDeleted = false
            variationLater.activity = activity

            let variationFirst = ActivityVariationMO(context: context)
            variationFirst.localID = ids.variationA
            variationFirst.remoteID = 10
            variationFirst.value = "First"
            variationFirst.position = 1
            variationFirst.syncDeleted = true
            variationFirst.activity = activity

            activity.variations = [variationLater, variationFirst]

            let record = ActivityRecordMO(context: context)
            record.localID = ids.record
            record.remoteID = 5
            record.lastModifiedVersion = 6
            record.startedAt = start
            record.endedAt = end
            record.timeZone = "Europe/Moscow"
            record.isDirty = true
            record.syncDeleted = false
            record.activity = activity
            record.variation = variationFirst

            return (category.toDTO(), activity.toDTO(), record.toDTO())
        }

        XCTAssertEqual(result.0.localID, ids.category)
        XCTAssertEqual(result.0.remoteID, 1)
        XCTAssertEqual(result.0.lastModifiedVersion, 2)
        XCTAssertEqual(result.0.baseName, "Category")
        XCTAssertEqual(result.0.code, .work)
        XCTAssertTrue(result.0.isDirty)

        XCTAssertEqual(result.1.localID, ids.activity)
        XCTAssertEqual(result.1.categoryLocalID, ids.category)
        XCTAssertEqual(result.1.categoryRemoteID, 1)
        XCTAssertEqual(result.1.color, .green)
        XCTAssertEqual(result.1.variations.map(\.remoteID), [10, 20])
        XCTAssertEqual(result.1.variations.map(\.value), ["First", "Later"])
        XCTAssertEqual(result.1.variations.map(\.isDeleted), [true, false])
        XCTAssertTrue(result.1.isDeleted)

        XCTAssertEqual(result.2.localID, ids.record)
        XCTAssertEqual(result.2.activityLocalID, ids.activity)
        XCTAssertEqual(result.2.activityRemoteID, 3)
        XCTAssertEqual(result.2.variationLocalID, ids.variationA)
        XCTAssertEqual(result.2.variationRemoteID, 10)
        XCTAssertEqual(result.2.startedAt, start)
        XCTAssertEqual(result.2.endedAt, end)
        XCTAssertEqual(result.2.timeZone, "Europe/Moscow")
    }

    func testChronometryMapsSnapshotsWithStableSorting() async throws {
        let coreDataStack = try makeInMemoryDomainCoreDataStack()
        let result = try await coreDataStack.performBackgroundTransaction { context in
            let chronometry = ChronometryMO(context: context)
            chronometry.localID = UUID()
            chronometry.remoteID = 50
            chronometry.lastModifiedVersion = 60
            chronometry.startDate = Date(timeIntervalSince1970: 1000)
            chronometry.endDate = Date(timeIntervalSince1970: 2000)
            chronometry.isFinished = true
            chronometry.timeZone = "Europe/Moscow"
            chronometry.isDirty = false
            chronometry.syncDeleted = false

            let catB = CategorySnapshotMO(context: context)
            catB.remoteID = 2
            catB.globalCategoryID = 22
            catB.baseName = "B"
            catB.code = .sleep
            catB.chronometry = chronometry

            let catA = CategorySnapshotMO(context: context)
            catA.remoteID = 1
            catA.globalCategoryID = 11
            catA.baseName = "A"
            catA.code = .work
            catA.chronometry = chronometry

            chronometry.categorySnapshots = [catB, catA]

            let activityB = ActivitySnapshotMO(context: context)
            activityB.remoteID = 12
            activityB.globalActivityID = 102
            activityB.name = "Run"
            activityB.iconName = "run"
            activityB.color = .blue
            activityB.chronometry = chronometry
            activityB.categorySnapshot = catB

            let variationB = ActivityVariationSnapshotMO(context: context)
            variationB.remoteID = 202
            variationB.globalActivityVariationID = 302
            variationB.value = "Zeta"
            variationB.chronometry = chronometry
            variationB.activitySnapshot = activityB

            let variationA = ActivityVariationSnapshotMO(context: context)
            variationA.remoteID = 201
            variationA.globalActivityVariationID = 301
            variationA.value = "Alpha"
            variationA.chronometry = chronometry
            variationA.activitySnapshot = activityB

            activityB.variationSnapshots = [variationB, variationA]

            let activityA = ActivitySnapshotMO(context: context)
            activityA.remoteID = 11
            activityA.globalActivityID = 101
            activityA.name = "Code"
            activityA.iconName = "hammer"
            activityA.color = .green
            activityA.chronometry = chronometry
            activityA.categorySnapshot = catA

            chronometry.activitySnapshots = [activityB, activityA]
            chronometry.activityVariationSnapshots = [variationB, variationA]

            let recordLater = ActivityRecordSnapshotMO(context: context)
            recordLater.remoteID = 402
            recordLater.globalActivityRecordID = 502
            recordLater.startedAt = Date(timeIntervalSince1970: 4000)
            recordLater.endedAt = Date(timeIntervalSince1970: 4500)
            recordLater.timeZone = "Europe/Moscow"
            recordLater.chronometry = chronometry
            recordLater.activitySnapshot = activityB
            recordLater.variationSnapshot = variationB

            let recordEarlier = ActivityRecordSnapshotMO(context: context)
            recordEarlier.remoteID = 401
            recordEarlier.globalActivityRecordID = 501
            recordEarlier.startedAt = Date(timeIntervalSince1970: 3000)
            recordEarlier.endedAt = nil
            recordEarlier.timeZone = "Europe/Moscow"
            recordEarlier.chronometry = chronometry
            recordEarlier.activitySnapshot = activityA
            recordEarlier.variationSnapshot = nil

            chronometry.activityRecordSnapshots = [recordLater, recordEarlier]

            return chronometry.toDTO()
        }

        XCTAssertEqual(result.remoteID, 50)
        XCTAssertEqual(result.lastModifiedVersion, 60)
        XCTAssertEqual(result.categorySnapshots.map(\.baseName), ["A", "B"])
        XCTAssertEqual(result.activitySnapshots.map(\.name), ["Code", "Run"])
        XCTAssertEqual(result.activitySnapshots.last?.variations.map(\.value), ["Alpha", "Zeta"])
        XCTAssertEqual(result.activityRecordSnapshots.map(\.remoteID), [401, 402])
    }
}
