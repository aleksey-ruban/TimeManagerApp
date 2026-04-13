import FeatureActivitiesModule
import FeatureAnalyticsModule
import FeatureSettingsModule
import Foundation
import UIKit

@MainActor
final class MainCoordinator {
    let rootViewController: UIViewController

    private let tabBarController: MainTabBarController
    private let homeNavigationController: UINavigationController
    private let analyticsNavigationController: UINavigationController
    private let activitiesCoordinator: ActivitiesCoordinatorProtocol
    private let analyticsCoordinator: AnalyticsCoordinatorProtocol
    private let settingsCoordinator: SettingsCoordinatorProtocol

    init(flow: MainFlow) {
        self.rootViewController = flow.rootViewController
        self.tabBarController = flow.tabBarController
        self.homeNavigationController = flow.homeNavigationController
        self.analyticsNavigationController = flow.analyticsNavigationController
        self.activitiesCoordinator = flow.activitiesCoordinator
        self.analyticsCoordinator = flow.analyticsCoordinator
        self.settingsCoordinator = flow.settingsCoordinator
    }

    func start() {
        homeNavigationController.setNavigationBarHidden(false, animated: false)
        analyticsNavigationController.setNavigationBarHidden(false, animated: false)
        configureHomeNavigationBarAppearance()
        analyticsCoordinator.start()
        settingsCoordinator.start()
    }

    func showActivitiesList() {
        tabBarController.selectTab(.home)
        activitiesCoordinator.showActivityList()
    }

    func showActivityOverview() {
        tabBarController.selectTab(.home)
        activitiesCoordinator.showActivityOverview()
    }

    func showActivityLauncher() {
        tabBarController.selectTab(.home)
        activitiesCoordinator.showActivityLauncher()
    }

    func showActivityEditor(activityID: UUID?) {
        tabBarController.selectTab(.home)
        activitiesCoordinator.showActivityEditor(activityID: activityID)
    }

    func showAnalyticsDashboard() {
        tabBarController.selectTab(.analytics)
        analyticsCoordinator.showDashboard()
    }

    func configureHomeNavigationBarAppearance() {
//        homeNavigationController.navigationBar.prefersLargeTitles = false
//
//        let appearance = UINavigationBarAppearance()
//        appearance.configureWithTransparentBackground()
//        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
//        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.78)
//        appearance.shadowColor = .clear
//
//        homeNavigationController.navigationBar.standardAppearance = appearance
//        homeNavigationController.navigationBar.scrollEdgeAppearance = appearance
//        homeNavigationController.navigationBar.compactAppearance = appearance
//        homeNavigationController.navigationBar.compactScrollEdgeAppearance = appearance
//        homeNavigationController.navigationBar.isTranslucent = true
//        homeNavigationController.navigationBar.tintColor = .label
    }
}
