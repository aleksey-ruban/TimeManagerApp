import Foundation

struct RemoteChronometryAnalyticsDTO: Decodable {
    let id: Int64?
    let userId: Int64?
    let chronometryId: Int64
    let days: [RemoteDayAnalyticsDTO]
    let issues: [RemoteAnalyticsIssueDTO]

    func toCachedModel(cachedAt: Date) throws -> CachedChronometryAnalytics {
        let parsedDays = try days.map { try $0.toCachedModel(chronometryRemoteID: chronometryId) }
        let weeklyIssues = try issues.map {
            try $0.toCachedModel(
                chronometryRemoteID: chronometryId,
                preferWeeklyAssociation: true
            )
        }

        return CachedChronometryAnalytics(
            analyticsID: id,
            userID: userId,
            chronometryRemoteID: chronometryId,
            cachedAt: cachedAt,
            days: parsedDays,
            weeklyIssues: weeklyIssues
        )
    }
}
