import Foundation

struct RemoteDayAnalyticsDTO: Decodable {
    let id: Int64?
    let chronometryId: Int64?
    let date: String
    let workTime: Int64?
    let leisureTime: Int64?
    let restTime: Int64?
    let isWorkDay: Bool?
    let workDayDuration: Int64?
    let focusScore: Double?
    let issues: [RemoteAnalyticsIssueDTO]

    func toCachedModel(chronometryRemoteID: Int64) throws -> CachedChronometryDayAnalytics {
        CachedChronometryDayAnalytics(
            dayID: id,
            chronometryRemoteID: chronometryId ?? chronometryRemoteID,
            date: try Self.dayFormatter.date(from: date).unwrap(or: RemotePayloadError.invalidDate(date)),
            workTime: workTime ?? 0,
            leisureTime: leisureTime ?? 0,
            restTime: restTime ?? 0,
            isWorkDay: isWorkDay ?? false,
            workDayDuration: workDayDuration ?? 0,
            focusScore: focusScore,
            issues: try issues.map {
                try $0.toCachedModel(
                    chronometryRemoteID: chronometryRemoteID,
                    preferWeeklyAssociation: false
                )
            }
        )
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
