import CommonSync
import CoreAuth
import CoreNetwork
import CoreSessionCleanup
import CoreStorage
import CoreSync
import CoreUserProfile
import FeatureActivitiesModule
import FeatureAnalyticsModule
import FeatureAuthModule
import FeatureSettingsModule
import Foundation
import UIKit

struct AppDependencyContainer {
    private let apiBaseURL: URL
    private let authFeatureService: AuthFeatureServiceProtocol
    private let authStateProvider: AuthStateProviderProtocol
    private let userProfileService: UserProfileServiceProtocol
    private let coreDataStack: CoreDataStackProtocol
    private let syncService: AppSyncServiceProtocol
    private let sessionCleanupService: SessionCleanupServiceProtocol
    private let unauthorizedSessionHandler: UnauthorizedSessionHandlerProtocol
    private let notificationCenter: NotificationCenter
    private let unauthenticatedNetworkExecutorFactory: NetworkExecutorFactoryProtocol
    private let authenticatedNetworkExecutorFactory: NetworkExecutorFactoryProtocol
    private let activitiesAssembly: ActivitiesFeatureAssembly
    private let analyticsAssembly: AnalyticsFeatureAssembly
    private let settingsAssembly: SettingsFeatureAssembly

    init(notificationCenter: NotificationCenter = .default) throws {
        let apiBaseURL = AppConfiguration.apiBaseURL()
        let coreDataStack = try CoreDataStack(
            configuration: CoreDataStackConfiguration(
                modelName: "TimeManagerApp",
                bundle: .main
            )
        )
        let sessionCleanupRegistry = AuthSessionCleanupRegistry()
        let reachabilityMonitor = NetworkReachabilityMonitor(notificationCenter: notificationCenter)
        let unauthenticatedNetworkExecutorFactory = NetworkAssembly(
            authInterceptor: nil,
            loggingConfiguration: AppConfiguration.networkLoggingConfiguration()
        ).makeExecutorFactory()

        let authModule = try AuthAssembly(
            configuration: AuthAPIConfiguration(baseURL: apiBaseURL),
            networkExecutorFactory: unauthenticatedNetworkExecutorFactory,
            sessionCleanupRegistry: sessionCleanupRegistry
        ).makeModule()
        let authenticatedNetworkExecutorFactory = NetworkAssembly(
            authInterceptor: authModule.authInterceptor,
            loggingConfiguration: AppConfiguration.networkLoggingConfiguration()
        ).makeExecutorFactory()
        let userProfileService = CoreUserProfileAssembly(
            networkExecutorFactory: authenticatedNetworkExecutorFactory,
            configuration: UserProfileAPIConfiguration(baseURL: apiBaseURL)
        ).makeService()
        let syncService = CommonSyncAssembly(
            syncAssembly: SyncAssembly(reachabilityMonitor: reachabilityMonitor),
            networkExecutorFactory: authenticatedNetworkExecutorFactory,
            coreDataStack: coreDataStack,
            apiConfiguration: SyncAPIConfiguration(baseURL: apiBaseURL),
            userProfileService: userProfileService
        ).makeSyncService()
        let sessionCleanupService = CoreSessionCleanupAssembly(
            userArtifactsStore: userProfileService,
            coreDataStack: coreDataStack
        ).makeService()
        sessionCleanupRegistry.service = sessionCleanupService

        self.apiBaseURL = apiBaseURL
        self.authFeatureService = authModule.authFeatureService
        self.authStateProvider = authModule.authStateProvider
        self.userProfileService = userProfileService
        self.coreDataStack = coreDataStack
        self.syncService = syncService
        self.sessionCleanupService = sessionCleanupService
        self.unauthorizedSessionHandler = UnauthorizedSessionHandler(sessionCleanupService: sessionCleanupService)
        self.notificationCenter = notificationCenter
        self.unauthenticatedNetworkExecutorFactory = unauthenticatedNetworkExecutorFactory
        self.authenticatedNetworkExecutorFactory = authenticatedNetworkExecutorFactory
        self.activitiesAssembly = ActivitiesFeatureAssembly(
            coreDataStack: coreDataStack,
            syncService: syncService
        )
        self.analyticsAssembly = AnalyticsFeatureAssembly(
            coreDataStack: coreDataStack,
            syncService: syncService,
            networkExecutorFactory: authenticatedNetworkExecutorFactory,
            configuration: AnalyticsFeatureAPIConfiguration(baseURL: apiBaseURL)
        )
        self.settingsAssembly = SettingsFeatureAssembly(
            userProfileService: userProfileService,
            authFeatureService: authFeatureService,
            sessionCleanupService: sessionCleanupService
        )
    }

    @MainActor
    func makeAppCoordinator(window: UIWindow) -> AppCoordinator {
        AppCoordinator(
            window: window,
            dependencies: .init(
                loadingViewController: makeLoadingViewController(),
                authFeatureService: authFeatureService,
                authStateProvider: authStateProvider,
                syncService: syncService,
                unauthorizedSessionHandler: unauthorizedSessionHandler,
                notificationCenter: notificationCenter,
                makeAuthFlow: { [self] onAuthorized in
                    makeAuthFlow(onAuthorized: onAuthorized)
                },
                makeMainCoordinator: { [self] onLogout in
                    makeMainCoordinator(onLogout: onLogout)
                }
            )
        )
    }

    @MainActor
    func saveApplicationState() throws {
        try coreDataStack.saveViewContextIfNeeded()
    }
}

private extension AppDependencyContainer {
    @MainActor
    func makeAuthFlow(onAuthorized: @escaping @MainActor () -> Void) -> AuthFlow {
        let module = AuthFeatureAssembly(
            configuration: AuthFeatureAPIConfiguration(baseURL: apiBaseURL),
            authFeatureService: authFeatureService,
            networkExecutorFactory: unauthenticatedNetworkExecutorFactory,
            onAuthorized: onAuthorized
        ).makeModule()

        return AuthFlow(
            rootViewController: module.rootViewController,
            coordinator: module.coordinator
        )
    }

    @MainActor
    func makeMainCoordinator(onLogout: @escaping @MainActor () -> Void) -> MainCoordinator {
        let tabBarController = MainTabBarController()
        let homeNavigationController = UINavigationController()
        let analyticsNavigationController = UINavigationController()
        let settingsNavigationController = UINavigationController()

        var openActivitiesHandler: (() -> Void)?
        var openLauncherHandler: (() -> Void)?
        var createActivityHandler: (() -> Void)?
        var openAnalyticsHandler: (() -> Void)?

        let activitySummaryWidget = activitiesAssembly.makeActivitySummaryWidget()
        let frequentWidget = activitiesAssembly.makeFrequentlyUsedWidget(
            onOpenAll: {
                openLauncherHandler?()
            },
            onAddNew: {
                createActivityHandler?()
            }
        )
        let myActivitiesWidget = activitiesAssembly.makeMyActivitiesWidget {
            openActivitiesHandler?()
        }
        let analyticsWidget = analyticsAssembly.makeOverviewWidget {
            openAnalyticsHandler?()
        }
        let homeViewController = MainHomeViewController(
            activitySummaryWidget: activitySummaryWidget,
            frequentWidget: frequentWidget,
            myActivitiesWidget: myActivitiesWidget,
            analyticsWidget: analyticsWidget
        )

        homeNavigationController.setViewControllers([homeViewController], animated: false)
        homeNavigationController.tabBarItem = UITabBarItem(
            title: "Главная",
            image: UIImage(systemName: "hourglass.bottomhalf.filled"),
            selectedImage: UIImage(systemName: "hourglass.bottomhalf.filled")
        )

        let analyticsCoordinator = analyticsAssembly.makeCoordinator(
            navigationController: analyticsNavigationController
        )
        analyticsNavigationController.tabBarItem = UITabBarItem(
            title: "Аналитика",
            image: UIImage(systemName: "sparkles.rectangle.stack"),
            selectedImage: UIImage(systemName: "sparkles.rectangle.stack")
        )

        let settingsCoordinator = settingsAssembly.makeCoordinator(
            navigationController: settingsNavigationController,
            onSessionFinished: onLogout
        )
        settingsNavigationController.tabBarItem = UITabBarItem(
            title: "Настройки",
            image: UIImage(systemName: "rectangle.grid.2x2"),
            selectedImage: UIImage(systemName: "rectangle.grid.2x2")
        )

        tabBarController.setViewControllers(
            [
                homeNavigationController,
                analyticsNavigationController,
                settingsNavigationController,
            ],
            animated: false
        )

        let activitiesCoordinator = activitiesAssembly.makeCoordinator(
            navigationController: homeNavigationController
        )

        let flow = MainFlow(
            rootViewController: tabBarController,
            tabBarController: tabBarController,
            homeNavigationController: homeNavigationController,
            analyticsNavigationController: analyticsNavigationController,
            activitiesCoordinator: activitiesCoordinator,
            analyticsCoordinator: analyticsCoordinator,
            settingsCoordinator: settingsCoordinator
        )
        let coordinator = MainCoordinator(flow: flow)

        openActivitiesHandler = { [weak coordinator] in
            coordinator?.showActivitiesList()
        }
        openLauncherHandler = { [weak coordinator] in
            coordinator?.showActivityLauncher()
        }
        createActivityHandler = { [weak coordinator] in
            coordinator?.showActivityEditor(activityID: nil)
        }
        openAnalyticsHandler = { [weak coordinator] in
            coordinator?.showAnalyticsDashboard()
        }
        activitySummaryWidget.onOpen = { [weak coordinator] in
            coordinator?.showActivityOverview()
        }
        frequentWidget.onDidSelectActivity = { [weak coordinator] activityID in
            coordinator?.showActivityEditor(activityID: activityID)
        }

        return coordinator
    }

    @MainActor
    func makeLoadingViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground

        let indicatorView = UIActivityIndicatorView(style: .large)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.startAnimating()

        viewController.view.addSubview(indicatorView)

        NSLayoutConstraint.activate([
            indicatorView.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            indicatorView.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
        ])

        return viewController
    }
}
