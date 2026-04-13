@preconcurrency import CoreData
import Foundation

@objc(ActivityRecordMO)
public final class ActivityRecordMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActivityRecordMO> {
        NSFetchRequest<ActivityRecordMO>(entityName: "ActivityRecordMO")
    }

    @NSManaged public var localID: UUID
    @NSManaged public var remoteID: NSNumber?
    @NSManaged public var lastModifiedVersion: NSNumber?
    @NSManaged public var startedAt: Date
    @NSManaged public var endedAt: Date?
    @NSManaged public var timeZone: String
    @NSManaged public var isDirty: Bool
    @NSManaged public var syncDeleted: Bool
    @NSManaged public var activity: ActivityMO
    @NSManaged public var variation: ActivityVariationMO?
}
