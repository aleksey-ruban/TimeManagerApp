@preconcurrency import CoreData
import Foundation

@objc(ChronometryMO)
public final class ChronometryMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChronometryMO> {
        NSFetchRequest<ChronometryMO>(entityName: "ChronometryMO")
    }

    @NSManaged public var localID: UUID
    @NSManaged public var remoteID: NSNumber?
    @NSManaged public var lastModifiedVersion: NSNumber?
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var isFinished: Bool
    @NSManaged public var timeZone: String
    @NSManaged public var isDirty: Bool
    @NSManaged public var syncDeleted: Bool
    @NSManaged public var categorySnapshots: Set<CategorySnapshotMO>?
    @NSManaged public var activitySnapshots: Set<ActivitySnapshotMO>?
    @NSManaged public var activityVariationSnapshots: Set<ActivityVariationSnapshotMO>?
    @NSManaged public var activityRecordSnapshots: Set<ActivityRecordSnapshotMO>?
}
