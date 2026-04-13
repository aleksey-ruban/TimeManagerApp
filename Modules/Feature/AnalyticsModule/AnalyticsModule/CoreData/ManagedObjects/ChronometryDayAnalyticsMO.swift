@preconcurrency import CoreData
import Foundation

@objc(ChronometryDayAnalyticsMO)
public final class ChronometryDayAnalyticsMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChronometryDayAnalyticsMO> {
        NSFetchRequest<ChronometryDayAnalyticsMO>(entityName: "ChronometryDayAnalyticsMO")
    }

    @NSManaged public var dayID: NSNumber?
    @NSManaged public var chronometryRemoteID: NSNumber
    @NSManaged public var date: Date
    @NSManaged public var workTime: NSNumber?
    @NSManaged public var leisureTime: NSNumber?
    @NSManaged public var restTime: NSNumber?
    @NSManaged public var isWorkDay: Bool
    @NSManaged public var workDayDuration: NSNumber?
    @NSManaged public var focusScore: NSNumber?
    @NSManaged public var analytics: ChronometryAnalyticsCacheMO
    @NSManaged public var issues: Set<ChronometryIssueAnalyticsMO>?
}
