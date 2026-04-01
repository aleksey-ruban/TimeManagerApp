import Foundation

public protocol ReachabilityMonitorProtocol: Sendable {
    var isReachable: Bool { get }
}
