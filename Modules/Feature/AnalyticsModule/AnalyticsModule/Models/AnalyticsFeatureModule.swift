import Foundation
import UIKit

@MainActor
public protocol AnalyticsCoordinatorProtocol: AnyObject {
    func start()
    func showDashboard()
}

@MainActor
public struct AnalyticsFeatureModule {
    public let coordinator: AnalyticsCoordinatorProtocol

    public init(coordinator: AnalyticsCoordinatorProtocol) {
        self.coordinator = coordinator
    }
}
