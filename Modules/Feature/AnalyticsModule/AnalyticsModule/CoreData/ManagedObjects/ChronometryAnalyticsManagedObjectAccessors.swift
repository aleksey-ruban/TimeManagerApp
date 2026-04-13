import Foundation

extension ChronometryAnalyticsCacheMO {
    var analyticsIDValue: Int64? { analyticsID?.int64Value }
    var userIDValue: Int64? { userID?.int64Value }
    var chronometryRemoteIDValue: Int64 { chronometryRemoteID.int64Value }

    func toCachedModel() -> CachedChronometryAnalytics {
        CachedChronometryAnalytics(
            analyticsID: analyticsIDValue,
            userID: userIDValue,
            chronometryRemoteID: chronometryRemoteIDValue,
            cachedAt: cachedAt,
            days: (days ?? [])
                .sorted { $0.date < $1.date }
                .map { $0.toCachedModel() },
            weeklyIssues: (issues ?? [])
                .sorted { ($0.issueIDValue ?? 0) < ($1.issueIDValue ?? 0) }
                .map { $0.toCachedModel() }
        )
    }
}

extension ChronometryDayAnalyticsMO {
    var dayIDValue: Int64? { dayID?.int64Value }
    var chronometryRemoteIDValue: Int64 { chronometryRemoteID.int64Value }
    var workTimeValue: Int64 { workTime?.int64Value ?? 0 }
    var leisureTimeValue: Int64 { leisureTime?.int64Value ?? 0 }
    var restTimeValue: Int64 { restTime?.int64Value ?? 0 }
    var workDayDurationValue: Int64 { workDayDuration?.int64Value ?? 0 }
    var focusScoreValue: Double? { focusScore?.doubleValue }

    func toCachedModel() -> CachedChronometryDayAnalytics {
        CachedChronometryDayAnalytics(
            dayID: dayIDValue,
            chronometryRemoteID: chronometryRemoteIDValue,
            date: date,
            workTime: workTimeValue,
            leisureTime: leisureTimeValue,
            restTime: restTimeValue,
            isWorkDay: isWorkDay,
            workDayDuration: workDayDurationValue,
            focusScore: focusScoreValue,
            issues: (issues ?? [])
                .sorted { ($0.issueIDValue ?? 0) < ($1.issueIDValue ?? 0) }
                .map { $0.toCachedModel() }
        )
    }
}

extension ChronometryIssueAnalyticsMO {
    var issueIDValue: Int64? { issueID?.int64Value }
    var chronometryRemoteIDValue: Int64? { chronometryRemoteID?.int64Value }
    var dayRemoteIDValue: Int64? { dayRemoteID?.int64Value }
    var code: ChronometryIssueCode? { ChronometryIssueCode(rawValue: codeRawValue) }
    var severity: ChronometryIssueSeverity? { ChronometryIssueSeverity(rawValue: severityRawValue) }

    func toCachedModel() -> CachedChronometryIssue {
        let parameters = (try? JSONDecoder().decode([ChronometryIssueParameter].self, from: paramsData ?? Data())) ?? []
        return CachedChronometryIssue(
            issueID: issueIDValue,
            code: code ?? .lowFocus,
            severity: severity ?? .low,
            parameters: parameters,
            chronometryRemoteID: chronometryRemoteIDValue,
            dayRemoteID: dayRemoteIDValue,
            recommendation: recommendation
        )
    }
}
