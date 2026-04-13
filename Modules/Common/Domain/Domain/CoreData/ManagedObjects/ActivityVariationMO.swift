@preconcurrency import CoreData
import Foundation

@objc(ActivityVariationMO)
public final class ActivityVariationMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActivityVariationMO> {
        NSFetchRequest<ActivityVariationMO>(entityName: "ActivityVariationMO")
    }

    @NSManaged public var localID: UUID
    @NSManaged public var remoteID: NSNumber?
    @NSManaged public var value: String
    @NSManaged public var position: Int64
    @NSManaged public var syncDeleted: Bool
    @NSManaged public var activity: ActivityMO
    @NSManaged public var records: Set<ActivityRecordMO>?
}
