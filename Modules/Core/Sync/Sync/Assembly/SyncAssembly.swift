import Foundation

public protocol SyncAssemblyProtocol: Sendable {
    func makeEngine() -> SyncEngineProtocol
}

public struct SyncAssembly: SyncAssemblyProtocol {
    private let reachabilityMonitor: ReachabilityMonitorProtocol

    public init(
        reachabilityMonitor: ReachabilityMonitorProtocol
    ) {
        self.reachabilityMonitor = reachabilityMonitor
    }

    public func makeEngine() -> SyncEngineProtocol {
        SyncEngine(reachabilityMonitor: reachabilityMonitor)
    }
}
