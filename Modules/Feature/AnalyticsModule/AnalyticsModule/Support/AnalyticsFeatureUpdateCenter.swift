import Foundation

public final class AnalyticsFeatureUpdateCenter: @unchecked Sendable {
    public static let shared = AnalyticsFeatureUpdateCenter()
    public static let didChangeNotification = Notification.Name("AnalyticsFeatureUpdateCenter.didChange")

    private let notificationCenter: NotificationCenter

    private init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    public func notifyDidChange() {
        notificationCenter.post(name: Self.didChangeNotification, object: nil)
    }
}
