import Foundation
import CoreSync

public protocol AppSyncServiceProtocol: Sendable {
    func run(trigger: SyncTrigger) async throws -> SyncRunResult
}

public extension Notification.Name {
    static let appSyncServiceDidFinishRun = Notification.Name("AppSyncService.didFinishRun")
}
