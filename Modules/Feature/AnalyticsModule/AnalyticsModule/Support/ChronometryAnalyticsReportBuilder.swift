import Foundation

struct ChronometryAnalyticsReportBuilder: Sendable {
    func build(from cache: CachedChronometryAnalytics) -> ChronometryAnalyticsReport {
        let daySummaries = cache.days
            .sorted { $0.date < $1.date }
            .map {
                ChronometryAnalyticsDaySummary(
                    date: $0.date,
                    workTime: $0.workTime,
                    leisureTime: $0.leisureTime,
                    restTime: $0.restTime,
                    isWorkDay: $0.isWorkDay,
                    workDayDuration: $0.workDayDuration,
                    focusScore: $0.focusScore,
                    issues: $0.issues
                        .sorted(by: compareIssues)
                        .map {
                            ChronometryDayIssueSummary(
                                code: $0.code,
                                severity: $0.severity,
                                recommendation: $0.recommendation,
                                parameters: $0.parameters
                            )
                        }
                )
            }

        let dailyIssuesByCode = Dictionary(grouping: cache.days.flatMap { day in
            day.issues.map { (issue: $0, date: day.date) }
        }, by: \.issue.code)

        var consumedCodes = Set<ChronometryIssueCode>()
        var groups: [ChronometryRecommendationGroup] = []

        for weeklyIssue in cache.weeklyIssues.sorted(by: compareIssues) {
            consumedCodes.insert(weeklyIssue.code)
            let dayOccurrences = (dailyIssuesByCode[weeklyIssue.code] ?? [])
                .map {
                    ChronometryRecommendationDayOccurrence(
                        date: $0.date,
                        severity: $0.issue.severity,
                        parameters: $0.issue.parameters
                    )
                }
                .sorted { $0.date < $1.date }

            groups.append(
                ChronometryRecommendationGroup(
                    code: weeklyIssue.code,
                    severity: weeklyIssue.severity,
                    recommendation: weeklyIssue.recommendation,
                    parameters: weeklyIssue.parameters,
                    dayOccurrences: dayOccurrences,
                    isWeeklySummary: true
                )
            )
        }

        for code in dailyIssuesByCode.keys.sorted(by: compareCodes) where consumedCodes.contains(code) == false {
            guard let issues = dailyIssuesByCode[code] else { continue }
            let sortedIssues = issues.sorted {
                if $0.date == $1.date {
                    return compareIssues($0.issue, $1.issue)
                }
                return $0.date < $1.date
            }
            guard let representative = sortedIssues.first?.issue else { continue }

            groups.append(
                ChronometryRecommendationGroup(
                    code: representative.code,
                    severity: sortedIssues.map(\.issue.severity).max(by: isLessSevere) ?? representative.severity,
                    recommendation: representative.recommendation,
                    parameters: representative.parameters,
                    dayOccurrences: sortedIssues.map {
                        ChronometryRecommendationDayOccurrence(
                            date: $0.date,
                            severity: $0.issue.severity,
                            parameters: $0.issue.parameters
                        )
                    },
                    isWeeklySummary: false
                )
            )
        }

        return ChronometryAnalyticsReport(
            fetchedAt: cache.cachedAt,
            daySummaries: daySummaries,
            recommendationGroups: groups.sorted { lhs, rhs in
                if lhs.severity == rhs.severity {
                    return compareCodes(lhs.code, rhs.code)
                }
                return compareSeverity(lhs.severity, rhs.severity)
            }
        )
    }

    private func compareIssues(_ lhs: CachedChronometryIssue, _ rhs: CachedChronometryIssue) -> Bool {
        if lhs.severity == rhs.severity {
            return compareCodes(lhs.code, rhs.code)
        }
        return compareSeverity(lhs.severity, rhs.severity)
    }

    private func compareSeverity(_ lhs: ChronometryIssueSeverity, _ rhs: ChronometryIssueSeverity) -> Bool {
        severityRank(lhs) > severityRank(rhs)
    }

    private func isLessSevere(_ lhs: ChronometryIssueSeverity, _ rhs: ChronometryIssueSeverity) -> Bool {
        severityRank(lhs) < severityRank(rhs)
    }

    private func severityRank(_ severity: ChronometryIssueSeverity) -> Int {
        switch severity {
        case .high:
            return 3
        case .medium:
            return 2
        case .low:
            return 1
        }
    }

    private func compareCodes(_ lhs: ChronometryIssueCode, _ rhs: ChronometryIssueCode) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
