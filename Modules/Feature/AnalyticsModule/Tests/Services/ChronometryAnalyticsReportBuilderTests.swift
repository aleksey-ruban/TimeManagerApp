import Foundation
import XCTest
@testable import FeatureAnalyticsModule

final class ChronometryAnalyticsReportBuilderTests: XCTestCase {
    func testWeeklyIssueAbsorbsDailyIssuesWithSameCode() throws {
        let builder = ChronometryAnalyticsReportBuilder()
        let cache = CachedChronometryAnalytics(
            analyticsID: 1,
            userID: 1,
            chronometryRemoteID: 24,
            cachedAt: Date(),
            days: [
                CachedChronometryDayAnalytics(
                    dayID: 1001,
                    chronometryRemoteID: 24,
                    date: makeDate(day: 1),
                    workTime: 300,
                    leisureTime: 60,
                    restTime: 120,
                    isWorkDay: true,
                    workDayDuration: 480,
                    focusScore: 0.42,
                    issues: [
                        CachedChronometryIssue(
                            issueID: 11,
                            code: .lowFocus,
                            severity: .medium,
                            parameters: [ChronometryIssueParameter(key: "FOCUS_SCORE", value: .double(0.42))],
                            chronometryRemoteID: nil,
                            dayRemoteID: 1001,
                            recommendation: "Делайте меньше переключений."
                        )
                    ]
                ),
                CachedChronometryDayAnalytics(
                    dayID: 1002,
                    chronometryRemoteID: 24,
                    date: makeDate(day: 2),
                    workTime: 320,
                    leisureTime: 40,
                    restTime: 140,
                    isWorkDay: true,
                    workDayDuration: 500,
                    focusScore: 0.39,
                    issues: [
                        CachedChronometryIssue(
                            issueID: 12,
                            code: .lowFocus,
                            severity: .high,
                            parameters: [ChronometryIssueParameter(key: "FOCUS_SCORE", value: .double(0.39))],
                            chronometryRemoteID: nil,
                            dayRemoteID: 1002,
                            recommendation: "Снижайте количество контекстных переключений."
                        )
                    ]
                )
            ],
            weeklyIssues: [
                CachedChronometryIssue(
                    issueID: 200,
                    code: .lowFocus,
                    severity: .high,
                    parameters: [ChronometryIssueParameter(key: "WEEKLY_OCCURRENCES", value: .integer(2))],
                    chronometryRemoteID: 24,
                    dayRemoteID: nil,
                    recommendation: "Сфокусируйте рабочие блоки."
                )
            ]
        )

        let report = builder.build(from: cache)

        XCTAssertEqual(report.recommendationGroups.count, 1)
        XCTAssertEqual(report.recommendationGroups.first?.code, .lowFocus)
        XCTAssertEqual(report.recommendationGroups.first?.isWeeklySummary, true)
        XCTAssertEqual(report.recommendationGroups.first?.dayOccurrences.count, 2)
        XCTAssertEqual(report.recommendationGroups.first?.parameters.first?.key, "WEEKLY_OCCURRENCES")
    }

    func testDailyOnlyIssuesRemainVisibleAsOwnGroup() throws {
        let builder = ChronometryAnalyticsReportBuilder()
        let cache = CachedChronometryAnalytics(
            analyticsID: 1,
            userID: 1,
            chronometryRemoteID: 24,
            cachedAt: Date(),
            days: [
                CachedChronometryDayAnalytics(
                    dayID: 1001,
                    chronometryRemoteID: 24,
                    date: makeDate(day: 1),
                    workTime: 300,
                    leisureTime: 60,
                    restTime: 120,
                    isWorkDay: true,
                    workDayDuration: 480,
                    focusScore: nil,
                    issues: [
                        CachedChronometryIssue(
                            issueID: 11,
                            code: .noBreaks,
                            severity: .medium,
                            parameters: [ChronometryIssueParameter(key: "TOTAL_BREAKS_MINUTES", value: .integer(6))],
                            chronometryRemoteID: nil,
                            dayRemoteID: 1001,
                            recommendation: "Добавьте короткие перерывы."
                        )
                    ]
                )
            ],
            weeklyIssues: []
        )

        let report = builder.build(from: cache)

        XCTAssertEqual(report.recommendationGroups.count, 1)
        XCTAssertEqual(report.recommendationGroups.first?.code, .noBreaks)
        XCTAssertEqual(report.recommendationGroups.first?.isWeeklySummary, false)
        XCTAssertEqual(report.recommendationGroups.first?.dayOccurrences.count, 1)
    }
}

private extension ChronometryAnalyticsReportBuilderTests {
    func makeDate(day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: 2026, month: 4, day: day))!
    }
}
