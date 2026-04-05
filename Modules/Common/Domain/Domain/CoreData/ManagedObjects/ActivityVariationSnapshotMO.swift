@preconcurrency import CoreData
import Foundation

@objc(ActivityVariationSnapshotMO)
public final class ActivityVariationSnapshotMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActivityVariationSnapshotMO> {
        NSFetchRequest<ActivityVariationSnapshotMO>(entityName: "ActivityVariationSnapshotMO")
    }

    @NSManaged public var remoteID: NSNumber?
    @NSManaged public var globalActivityVariationID: NSNumber?
    @NSManaged public var value: String
    @NSManaged public var chronometry: ChronometryMO
    @NSManaged public var activitySnapshot: ActivitySnapshotMO
    @NSManaged public var activityRecords: Set<ActivityRecordSnapshotMO>?
}
