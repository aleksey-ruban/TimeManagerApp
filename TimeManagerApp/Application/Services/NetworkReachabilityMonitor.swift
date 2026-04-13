import CoreSync
import Foundation
import Network

extension Notification.Name {
    static let networkReachabilityDidBecomeReachable = Notification.Name("NetworkReachability.didBecomeReachable")
}

final class NetworkReachabilityMonitor: ReachabilityMonitorProtocol, @unchecked Sendable {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private let notificationCenter: NotificationCenter
    private let lock = NSLock()

    private var _isReachable = true

    var isReachable: Bool {
        lock.withLock {
            _isReachable
        }
    }

    init(
        monitor: NWPathMonitor = NWPathMonitor(),
        queue: DispatchQueue = DispatchQueue(label: "com.alekseyruban.TimeManagerApp.NetworkReachability"),
        notificationCenter: NotificationCenter = .default
    ) {
        self.monitor = monitor
        self.queue = queue
        self.notificationCenter = notificationCenter

        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    private func handlePathUpdate(_ path: NWPath) {
        let newValue = path.status == .satisfied
        let shouldNotify = lock.withLock { () -> Bool in
            let oldValue = _isReachable
            _isReachable = newValue
            return oldValue == false && newValue == true
        }

        guard shouldNotify else {
            return
        }

        notificationCenter.post(name: .networkReachabilityDidBecomeReachable, object: nil)
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
