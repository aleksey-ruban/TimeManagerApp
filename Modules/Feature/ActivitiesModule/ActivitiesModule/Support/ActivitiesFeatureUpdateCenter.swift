import Foundation

public final class ActivitiesFeatureUpdateCenter: @unchecked Sendable {
    public static let shared = ActivitiesFeatureUpdateCenter()
    public static let didChangeNotification = Notification.Name("ActivitiesFeatureUpdateCenter.didChange")

    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    public func notifyDidChange() {
        notificationCenter.post(name: Self.didChangeNotification, object: nil)
    }
}

public final class NotificationObserverBag: @unchecked Sendable {
    public var observers: [NSObjectProtocol] = []

    public init() {}

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }
}
