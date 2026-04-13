@preconcurrency import CoreData
import Foundation

@objc(ChronometryIssueAnalyticsMO)
public final class ChronometryIssueAnalyticsMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChronometryIssueAnalyticsMO> {
        NSFetchRequest<ChronometryIssueAnalyticsMO>(entityName: "ChronometryIssueAnalyticsMO")
    }

    @NSManaged public var issueID: NSNumber?
    @NSManaged public var codeRawValue: String
    @NSManaged public var severityRawValue: String
    @NSManaged public var paramsData: Data?
    @NSManaged public var recommendation: String
    @NSManaged public var chronometryRemoteID: NSNumber?
    @NSManaged public var dayRemoteID: NSNumber?
    @NSManaged public var analytics: ChronometryAnalyticsCacheMO?
    @NSManaged public var day: ChronometryDayAnalyticsMO?
}
