@preconcurrency import CoreData
import Foundation

@objc(CategoryMO)
public final class CategoryMO: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoryMO> {
        NSFetchRequest<CategoryMO>(entityName: "CategoryMO")
    }

    @NSManaged public var localID: UUID
    @NSManaged public var remoteID: NSNumber?
    @NSManaged public var lastModifiedVersion: NSNumber?
    @NSManaged public var baseName: String
    @NSManaged public var codeRawValue: String?
    @NSManaged public var isDirty: Bool
    @NSManaged public var syncDeleted: Bool
    @NSManaged public var activities: Set<ActivityMO>?
}
