import CoreSessionCleanup
import Foundation

public final class AuthSessionCleanupRegistry: @unchecked Sendable {
    public var service: SessionCleanupServiceProtocol?

    public init(service: SessionCleanupServiceProtocol? = nil) {
        self.service = service
    }
}
