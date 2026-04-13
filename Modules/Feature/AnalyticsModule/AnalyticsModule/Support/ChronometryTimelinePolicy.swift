import Domain
import Foundation

struct ChronometryTimelinePolicy: Sendable {
    static let trackingDurationDays = 7
    static let preferredRestartCooldownDays = 60
    static let sameDayStartHour = 9
    static let finishHour = 21

    func proposedFirstDay(for date: Date, timeZone: TimeZone) -> Date {
        let calendar = makeCalendar(timeZone: timeZone)
        let localComponents = calendar.dateComponents(in: timeZone, from: date)
        let startOfCurrentDay = calendar.startOfDay(for: date)

        guard let hour = localComponents.hour else {
            return startOfCurrentDay
        }

        if hour < Self.sameDayStartHour {
            return startOfCurrentDay
        }

        return calendar.date(byAdding: .day, value: 1, to: startOfCurrentDay) ?? startOfCurrentDay
    }

    func lastDay(forFirstDay firstDay: Date, timeZone: TimeZone) -> Date {
        let calendar = makeCalendar(timeZone: timeZone)
        return calendar.date(byAdding: .day, value: Self.trackingDurationDays - 1, to: firstDay) ?? firstDay
    }

    func recordedDays(for chronometry: Chronometry, asOf now: Date) -> Int {
        let timeZone = resolveTimeZone(identifier: chronometry.timeZone)
        let calendar = makeCalendar(timeZone: timeZone)
        let firstDay = calendar.startOfDay(for: chronometry.startDate)
        let lastDay = calendar.startOfDay(for: chronometry.endDate)
        let today = calendar.startOfDay(for: now)

        if today < firstDay {
            return 0
        }

        let effectiveLastCoveredDay = min(today, lastDay)
        let distance = calendar.dateComponents([.day], from: firstDay, to: effectiveLastCoveredDay).day ?? 0
        return min(Self.trackingDurationDays, max(0, distance + 1))
    }

    func canFinish(_ chronometry: Chronometry, now: Date) -> Bool {
        let timeZone = resolveTimeZone(identifier: chronometry.timeZone)
        let calendar = makeCalendar(timeZone: timeZone)
        let lastDay = calendar.startOfDay(for: chronometry.endDate)
        let nowDay = calendar.startOfDay(for: now)

        if nowDay > lastDay {
            return true
        }

        guard nowDay == lastDay else {
            return false
        }

        let finishMoment = calendar.date(
            bySettingHour: Self.finishHour,
            minute: 0,
            second: 0,
            of: lastDay
        ) ?? lastDay

        return now >= finishMoment
    }

    func finishAvailableFrom(_ chronometry: Chronometry) -> Date {
        let timeZone = resolveTimeZone(identifier: chronometry.timeZone)
        let calendar = makeCalendar(timeZone: timeZone)
        let lastDay = calendar.startOfDay(for: chronometry.endDate)
        return calendar.date(bySettingHour: Self.finishHour, minute: 0, second: 0, of: lastDay) ?? lastDay
    }

    func isScheduled(_ chronometry: Chronometry, now: Date) -> Bool {
        let timeZone = resolveTimeZone(identifier: chronometry.timeZone)
        let calendar = makeCalendar(timeZone: timeZone)
        return now < calendar.startOfDay(for: chronometry.startDate)
    }

    func recommendedStartDate(after chronometry: Chronometry) -> Date {
        let timeZone = resolveTimeZone(identifier: chronometry.timeZone)
        let calendar = makeCalendar(timeZone: timeZone)
        let lastDay = calendar.startOfDay(for: chronometry.endDate)
        return calendar.date(byAdding: .day, value: Self.preferredRestartCooldownDays, to: lastDay) ?? lastDay
    }

    func resolveTimeZone(identifier: String) -> TimeZone {
        TimeZone(identifier: identifier) ?? .current
    }

    private func makeCalendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
