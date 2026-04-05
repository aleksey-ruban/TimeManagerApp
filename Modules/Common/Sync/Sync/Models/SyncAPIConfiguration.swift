import Foundation

public struct SyncAPIConfiguration: Sendable {
    public let baseURL: URL
    public let pullPath: String
    public let pushPath: String
    public let initialPullBatchSize: Int

    public init(
        baseURL: URL,
        pullPath: String = "/api/v1/activities/sync/pull",
        pushPath: String = "/api/v1/activities/sync/push",
        initialPullBatchSize: Int = 5000
    ) {
        self.baseURL = baseURL
        self.pullPath = pullPath
        self.pushPath = pushPath
        self.initialPullBatchSize = initialPullBatchSize
    }
}
