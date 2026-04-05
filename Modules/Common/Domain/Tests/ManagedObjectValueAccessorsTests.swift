import CoreData
import Domain
import XCTest

final class ManagedObjectValueAccessorsTests: XCTestCase {
    func testAccessorsConvertRawValuesToTypedValues() {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: DomainManagedObjectModelFactory.makeModel())

        let category = CategoryMO(context: context)
        category.remoteID = 11
        category.lastModifiedVersion = 12
        category.codeRawValue = CategoryCode.workout.rawValue

        let activity = ActivityMO(context: context)
        activity.remoteID = 21
        activity.lastModifiedVersion = 22
        activity.colorRawValue = ActivityColor.green.rawValue

        XCTAssertEqual(category.remoteIDValue, 11)
        XCTAssertEqual(category.lastModifiedVersionValue, 12)
        XCTAssertEqual(category.code, .workout)
        XCTAssertEqual(activity.remoteIDValue, 21)
        XCTAssertEqual(activity.lastModifiedVersionValue, 22)
        XCTAssertEqual(activity.color, .green)
    }
}
