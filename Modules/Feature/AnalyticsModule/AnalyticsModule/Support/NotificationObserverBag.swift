import Foundation

final class NotificationObserverBag: @unchecked Sendable {
    var observers: [NSObjectProtocol] = []

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }
}
