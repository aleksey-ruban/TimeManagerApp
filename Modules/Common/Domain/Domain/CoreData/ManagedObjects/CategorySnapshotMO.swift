@preconcurrency import CoreData
import Foundation

@objc(CategorySnapshotMO)
public final class CategorySnapshotMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategorySnapshotMO> {
        NSFetchRequest<CategorySnapshotMO>(entityName: "CategorySnapshotMO")
    }

    @NSManaged public var remoteID: NSNumber?
    @NSManaged public var globalCategoryID: NSNumber?
    @NSManaged public var baseName: String
    @NSManaged public var codeRawValue: String?
    @NSManaged public var chronometry: ChronometryMO
    @NSManaged public var activitySnapshots: Set<ActivitySnapshotMO>?
}
