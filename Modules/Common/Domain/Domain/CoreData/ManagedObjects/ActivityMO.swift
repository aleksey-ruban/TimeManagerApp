@preconcurrency import CoreData
import Foundation

@objc(ActivityMO)
public final class ActivityMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActivityMO> {
        NSFetchRequest<ActivityMO>(entityName: "ActivityMO")
    }

    @NSManaged public var localID: UUID
    @NSManaged public var remoteID: NSNumber?
    @NSManaged public var lastModifiedVersion: NSNumber?
    @NSManaged public var name: String
    @NSManaged public var iconName: String
    @NSManaged public var colorRawValue: String
    @NSManaged public var isDirty: Bool
    @NSManaged public var syncDeleted: Bool
    @NSManaged public var category: CategoryMO?
    @NSManaged public var variations: Set<ActivityVariationMO>?
    @NSManaged public var records: Set<ActivityRecordMO>?
}
