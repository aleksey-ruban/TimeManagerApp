@preconcurrency import CoreData
import Foundation

@objc(ActivityRecordSnapshotMO)
public final class ActivityRecordSnapshotMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActivityRecordSnapshotMO> {
        NSFetchRequest<ActivityRecordSnapshotMO>(entityName: "ActivityRecordSnapshotMO")
    }

    @NSManaged public var remoteID: NSNumber?
    @NSManaged public var globalActivityRecordID: NSNumber?
    @NSManaged public var startedAt: Date
    @NSManaged public var endedAt: Date?
    @NSManaged public var timeZone: String
    @NSManaged public var chronometry: ChronometryMO
    @NSManaged public var activitySnapshot: ActivitySnapshotMO
    @NSManaged public var variationSnapshot: ActivityVariationSnapshotMO?
}
