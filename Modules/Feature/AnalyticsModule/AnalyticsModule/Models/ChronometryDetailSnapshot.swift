import Domain
import Foundation
import UIKit

struct ChronometryDetailSnapshot: Sendable {
    let chronometry: Chronometry
    let analyticsStatus: ChronometryAnalyticsStatus
    let activityTimelineEntries: [ChronometryActivityTimelineEntry]
}

struct ChronometryActivityTimelineEntry: @unchecked Sendable {
    let startedAt: Date
    let endedAt: Date?
    let activityName: String
    let categoryName: String?
    let variationName: String?
    let iconName: String
    let color: UIColor
}
