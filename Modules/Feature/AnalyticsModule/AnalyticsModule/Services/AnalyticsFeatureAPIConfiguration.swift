import Foundation

public struct AnalyticsFeatureAPIConfiguration: Sendable {
    public let baseURL: URL
    public let analyticsPath: String

    public init(
        baseURL: URL,
        analyticsPath: String = "/api/v1/analytics/analytic"
    ) {
        self.baseURL = baseURL
        self.analyticsPath = analyticsPath
    }
}
