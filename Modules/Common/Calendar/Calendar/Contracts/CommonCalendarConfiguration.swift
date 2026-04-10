import Foundation

public struct CommonCalendarConfiguration: Sendable {
    public let selectedDate: Date
    public let highlightedDates: Set<Date>
    public let allowsFutureDates: Bool

    public init(
        selectedDate: Date,
        highlightedDates: Set<Date> = [],
        allowsFutureDates: Bool = false
    ) {
        self.selectedDate = selectedDate
        self.highlightedDates = highlightedDates
        self.allowsFutureDates = allowsFutureDates
    }
}
