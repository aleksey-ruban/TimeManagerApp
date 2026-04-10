import Foundation

protocol CommonCalendarMonthProviding {
    func makeMonthDates(configuration: CommonCalendarConfiguration, now: Date) -> [Date]
    func makeWeeks(for monthDate: Date) -> [[Date?]]
    func isDateEnabled(_ date: Date, configuration: CommonCalendarConfiguration, now: Date) -> Bool
    func monthTitle(for monthDate: Date) -> String
}
