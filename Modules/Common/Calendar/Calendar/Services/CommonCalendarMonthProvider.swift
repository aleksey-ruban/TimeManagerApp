import Foundation

struct CommonCalendarMonthProvider: CommonCalendarMonthProviding {
    private let calendar: Calendar
    private let earliestMonth: Date
    private let latestMonthCap: Date
    private let monthTitleFormatter: DateFormatter

    init(calendar: Calendar = .current) {
        self.calendar = calendar
        self.earliestMonth = calendar.date(from: DateComponents(year: 2025, month: 7, day: 1)) ?? Date()
        self.latestMonthCap = calendar.date(from: DateComponents(year: 2026, month: 7, day: 1)) ?? Date()

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        self.monthTitleFormatter = formatter
    }

    func makeMonthDates(configuration: CommonCalendarConfiguration, now: Date) -> [Date] {
        let earliest = startOfMonth(for: earliestMonth)
        let latestAnchor = configuration.allowsFutureDates ? latestMonthCap : now
        let latest = startOfMonth(for: min(latestAnchor, latestMonthCap))

        guard earliest <= latest else {
            return [earliest]
        }

        var result: [Date] = []
        var cursor = earliest

        while cursor <= latest {
            result.append(cursor)
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: cursor) else {
                break
            }
            cursor = nextMonth
        }

        return result
    }

    func makeWeeks(for monthDate: Date) -> [[Date?]] {
        guard
            let dayRange = calendar.range(of: .day, in: .month, for: monthDate),
            let monthInterval = calendar.dateInterval(of: .month, for: monthDate)
        else {
            return []
        }

        let firstWeekday = mondayBasedWeekdayIndex(for: monthInterval.start)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in dayRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                days.append(date)
            }
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }

        return stride(from: 0, to: days.count, by: 7).map { index in
            Array(days[index ..< min(index + 7, days.count)])
        }
    }

    func isDateEnabled(_ date: Date, configuration: CommonCalendarConfiguration, now: Date) -> Bool {
        configuration.allowsFutureDates || calendar.startOfDay(for: date) <= calendar.startOfDay(for: now)
    }

    func monthTitle(for monthDate: Date) -> String {
        let title = monthTitleFormatter.string(from: monthDate)
        return String(title.prefix(1)).uppercased() + String(title.dropFirst())
    }
}

private extension CommonCalendarMonthProvider {
    func startOfMonth(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    func mondayBasedWeekdayIndex(for date: Date) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return (weekday + 5) % 7
    }
}
