import FeatureActivitiesModule
import FeatureAnalyticsModule
import FeatureSettingsModule
import UIKit

@MainActor
struct MainFlow {
    let rootViewController: UIViewController
    let tabBarController: MainTabBarController
    let homeNavigationController: UINavigationController
    let analyticsNavigationController: UINavigationController
    let activitiesCoordinator: ActivitiesCoordinatorProtocol
    let analyticsCoordinator: AnalyticsCoordinatorProtocol
    let settingsCoordinator: SettingsCoordinatorProtocol
}
