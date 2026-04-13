import Domain
import Foundation
import XCTest
@testable import FeatureAnalyticsModule

final class ChronometryTimelinePolicyTests: XCTestCase {
    func testProposedFirstDayUsesCurrentDayBeforeNineAM() throws {
        let policy = ChronometryTimelinePolicy()
        let timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/Moscow"))
        let date = makeDate(year: 2026, month: 4, day: 11, hour: 8, minute: 45, timeZone: timeZone)

        let firstDay = policy.proposedFirstDay(for: date, timeZone: timeZone)

        XCTAssertEqual(firstDay, makeDate(year: 2026, month: 4, day: 11, hour: 0, minute: 0, timeZone: timeZone))
    }

    func testProposedFirstDayUsesNextDayAfterNineAM() throws {
        let policy = ChronometryTimelinePolicy()
        let timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/Moscow"))
        let date = makeDate(year: 2026, month: 4, day: 11, hour: 10, minute: 5, timeZone: timeZone)

        let firstDay = policy.proposedFirstDay(for: date, timeZone: timeZone)

        XCTAssertEqual(firstDay, makeDate(year: 2026, month: 4, day: 12, hour: 0, minute: 0, timeZone: timeZone))
    }

    func testCanFinishOnlyAfterTwentyOneOnLastDay() throws {
        let policy = ChronometryTimelinePolicy()
        let timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/Moscow"))
        let chronometry = makeChronometry(
            startDate: makeDate(year: 2026, month: 4, day: 11, hour: 0, minute: 0, timeZone: timeZone),
            endDate: makeDate(year: 2026, month: 4, day: 17, hour: 0, minute: 0, timeZone: timeZone),
            timeZone: timeZone.identifier
        )

        XCTAssertFalse(policy.canFinish(
            chronometry,
            now: makeDate(year: 2026, month: 4, day: 17, hour: 20, minute: 59, timeZone: timeZone)
        ))
        XCTAssertTrue(policy.canFinish(
            chronometry,
            now: makeDate(year: 2026, month: 4, day: 17, hour: 21, minute: 0, timeZone: timeZone)
        ))
        XCTAssertTrue(policy.canFinish(
            chronometry,
            now: makeDate(year: 2026, month: 4, day: 18, hour: 8, minute: 0, timeZone: timeZone)
        ))
    }

    func testRecordedDaysCapsAtSeven() throws {
        let policy = ChronometryTimelinePolicy()
        let timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/Moscow"))
        let chronometry = makeChronometry(
            startDate: makeDate(year: 2026, month: 4, day: 11, hour: 0, minute: 0, timeZone: timeZone),
            endDate: makeDate(year: 2026, month: 4, day: 17, hour: 0, minute: 0, timeZone: timeZone),
            timeZone: timeZone.identifier
        )

        let recordedDays = policy.recordedDays(
            for: chronometry,
            asOf: makeDate(year: 2026, month: 4, day: 23, hour: 12, minute: 0, timeZone: timeZone)
        )

        XCTAssertEqual(recordedDays, 7)
    }
}

private extension ChronometryTimelinePolicyTests {
    func makeChronometry(startDate: Date, endDate: Date, timeZone: String) -> Chronometry {
        Chronometry(
            localID: UUID(),
            remoteID: 100,
            lastModifiedVersion: 1,
            startDate: startDate,
            endDate: endDate,
            isFinished: false,
            timeZone: timeZone,
            categorySnapshots: [],
            activitySnapshots: [],
            activityRecordSnapshots: [],
            isDirty: false,
            isDeleted: false
        )
    }

    func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        timeZone: TimeZone
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(
            timeZone: timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ))!
    }
}
