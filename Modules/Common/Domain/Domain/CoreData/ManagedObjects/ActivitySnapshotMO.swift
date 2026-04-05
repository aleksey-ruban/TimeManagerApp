@preconcurrency import CoreData
import Foundation

@objc(ActivitySnapshotMO)
public final class ActivitySnapshotMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActivitySnapshotMO> {
        NSFetchRequest<ActivitySnapshotMO>(entityName: "ActivitySnapshotMO")
    }

    @NSManaged public var remoteID: NSNumber?
    @NSManaged public var globalActivityID: NSNumber?
    @NSManaged public var name: String
    @NSManaged public var iconName: String
    @NSManaged public var colorRawValue: String
    @NSManaged public var chronometry: ChronometryMO
    @NSManaged public var categorySnapshot: CategorySnapshotMO?
    @NSManaged public var variationSnapshots: Set<ActivityVariationSnapshotMO>?
    @NSManaged public var activityRecordSnapshots: Set<ActivityRecordSnapshotMO>?
}
