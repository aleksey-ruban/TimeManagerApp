@preconcurrency import CoreData
import Foundation

@objc(ChronometryAnalyticsCacheMO)
public final class ChronometryAnalyticsCacheMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChronometryAnalyticsCacheMO> {
        NSFetchRequest<ChronometryAnalyticsCacheMO>(entityName: "ChronometryAnalyticsCacheMO")
    }

    @NSManaged public var analyticsID: NSNumber?
    @NSManaged public var userID: NSNumber?
    @NSManaged public var chronometryRemoteID: NSNumber
    @NSManaged public var cachedAt: Date
    @NSManaged public var days: Set<ChronometryDayAnalyticsMO>?
    @NSManaged public var issues: Set<ChronometryIssueAnalyticsMO>?
}
