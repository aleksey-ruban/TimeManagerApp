import Foundation

struct RemoteAnalyticsIssueDTO: Decodable {
    let id: Int64?
    let code: ChronometryIssueCode
    let severity: ChronometryIssueSeverity
    let params: [String: AnalyticsPrimitiveValue]
    let chronometryId: Int64?
    let dayId: Int64?
    let recommendation: String?

    func toCachedModel(
        chronometryRemoteID: Int64,
        preferWeeklyAssociation: Bool
    ) throws -> CachedChronometryIssue {
        let isWeekly = preferWeeklyAssociation || chronometryId != nil
        let orderedParameters = params
            .map { ChronometryIssueParameter(key: $0.key, value: $0.value) }
            .sorted { $0.key < $1.key }

        return CachedChronometryIssue(
            issueID: id,
            code: code,
            severity: severity,
            parameters: orderedParameters,
            chronometryRemoteID: isWeekly ? (chronometryId ?? chronometryRemoteID) : nil,
            dayRemoteID: isWeekly ? nil : dayId,
            recommendation: recommendation ?? ""
        )
    }
}
