import XCTest
@testable import CommonCalendar

final class CommonCalendarMonthProviderTests: XCTestCase {
    func testMakeMonthDatesStartsFromJuly2025AndEndsAtCurrentMonthWhenFutureDatesDisabled() {
        let provider = CommonCalendarMonthProvider(calendar: makeCalendar())
        let now = makeDate(year: 2026, month: 4, day: 10)
        let configuration = CommonCalendarConfiguration(
            selectedDate: now,
            allowsFutureDates: false
        )

        let months = provider.makeMonthDates(configuration: configuration, now: now)

        XCTAssertEqual(months.first, makeDate(year: 2025, month: 7, day: 1))
        XCTAssertEqual(months.last, makeDate(year: 2026, month: 4, day: 1))
        XCTAssertEqual(months.count, 10)
    }

    func testMakeMonthDatesIncludesMonthsThroughJuly2026WhenFutureDatesEnabled() {
        let provider = CommonCalendarMonthProvider(calendar: makeCalendar())
        let now = makeDate(year: 2026, month: 4, day: 10)
        let configuration = CommonCalendarConfiguration(
            selectedDate: now,
            allowsFutureDates: true
        )

        let months = provider.makeMonthDates(configuration: configuration, now: now)

        XCTAssertEqual(months.first, makeDate(year: 2025, month: 7, day: 1))
        XCTAssertEqual(months.last, makeDate(year: 2026, month: 7, day: 1))
        XCTAssertEqual(months.count, 13)
    }

    func testMakeWeeksAddsLeadingNilSlotsUsingMondayBasedWeekdayLayout() {
        let provider = CommonCalendarMonthProvider(calendar: makeCalendar())

        let weeks = provider.makeWeeks(for: makeDate(year: 2025, month: 7, day: 1))

        XCTAssertEqual(weeks.count, 5)
        XCTAssertNil(weeks[0][0])
        XCTAssertEqual(weeks[0][1], makeDate(year: 2025, month: 7, day: 1))
        XCTAssertEqual(weeks[0][6], makeDate(year: 2025, month: 7, day: 6))
    }

    func testIsDateEnabledReturnsFalseForFutureDatesWhenFutureDatesDisabled() {
        let provider = CommonCalendarMonthProvider(calendar: makeCalendar())
        let now = makeDate(year: 2026, month: 4, day: 10)
        let futureDate = makeDate(year: 2026, month: 4, day: 11)
        let configuration = CommonCalendarConfiguration(
            selectedDate: now,
            allowsFutureDates: false
        )

        let isEnabled = provider.isDateEnabled(futureDate, configuration: configuration, now: now)

        XCTAssertFalse(isEnabled)
    }

    func testIsDateEnabledReturnsTrueForFutureDatesWhenFutureDatesAllowed() {
        let provider = CommonCalendarMonthProvider(calendar: makeCalendar())
        let now = makeDate(year: 2026, month: 4, day: 10)
        let futureDate = makeDate(year: 2026, month: 4, day: 11)
        let configuration = CommonCalendarConfiguration(
            selectedDate: now,
            allowsFutureDates: true
        )

        let isEnabled = provider.isDateEnabled(futureDate, configuration: configuration, now: now)

        XCTAssertTrue(isEnabled)
    }
}

private extension CommonCalendarMonthProviderTests {
    func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Moscow")!
        calendar.locale = Locale(identifier: "ru_RU")
        return calendar
    }

    func makeDate(year: Int, month: Int, day: Int) -> Date {
        makeCalendar().date(from: DateComponents(year: year, month: month, day: day))!
    }
}
