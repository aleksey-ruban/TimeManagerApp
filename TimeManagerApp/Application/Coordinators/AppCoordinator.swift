import CommonSync
import CoreAuth
import CoreSync
import FeatureAuthModule
import OSLog
import UIKit

@MainActor
final class AppCoordinator {
    struct Dependencies {
        let loadingViewController: UIViewController
        let authFeatureService: AuthFeatureServiceProtocol
        let authStateProvider: AuthStateProviderProtocol
        let syncService: AppSyncServiceProtocol
        let unauthorizedSessionHandler: UnauthorizedSessionHandlerProtocol
        let notificationCenter: NotificationCenter
        let makeAuthFlow: @MainActor (@escaping @MainActor () -> Void) -> AuthFlow
        let makeMainCoordinator: @MainActor (@escaping @MainActor () -> Void) -> MainCoordinator
    }

    private enum Flow {
        case loading
        case authentication
        case main
    }

    private static let logger = Logger(
        subsystem: "com.alekseyruban.TimeManagerApp",
        category: "AppCoordinator"
    )

    private let window: UIWindow
    private let dependencies: Dependencies

    private var authCoordinator: AuthCoordinatorProtocol?
    private var mainCoordinator: MainCoordinator?
    private var authStateObservationTask: Task<Void, Never>?
    private var reachabilityObservationTask: Task<Void, Never>?
    private var currentFlow: Flow = .loading

    init(window: UIWindow, dependencies: Dependencies) {
        self.window = window
        self.dependencies = dependencies
    }

    deinit {
        authStateObservationTask?.cancel()
        reachabilityObservationTask?.cancel()
    }

    func start() {
        startObservingAuthState()
        startObservingReachability()
        window.rootViewController = dependencies.loadingViewController

        Task { [weak self] in
            guard let self else { return }

            let authorizationState = await dependencies.authFeatureService.launchAuthorizationState()
            await MainActor.run {
                switch authorizationState {
                case .authenticated:
                    showMainFlow()
                case .unauthenticated:
                    showAuthenticationFlow()
                }
            }
        }
    }
}

private extension AppCoordinator {
    func startObservingAuthState() {
        authStateObservationTask?.cancel()

        let authStateProvider = dependencies.authStateProvider
        authStateObservationTask = Task { [weak self] in
            let updates = await authStateProvider.stateUpdates()

            for await state in updates {
                guard Task.isCancelled == false else { return }
                await self?.handleAuthStateUpdate(state)
            }
        }
    }

    func startObservingReachability() {
        reachabilityObservationTask?.cancel()

        let notificationCenter = dependencies.notificationCenter
        reachabilityObservationTask = Task { [weak self] in
            let notifications = notificationCenter.notifications(
                named: .networkReachabilityDidBecomeReachable
            )

            for await _ in notifications {
                guard Task.isCancelled == false else { return }
                self?.handleReachabilityRestored()
            }
        }
    }

    func handleReachabilityRestored() {
        guard currentFlow == .main else { return }

        Self.logger.info("network became reachable. scheduling sync.")
        runSync(trigger: .manual, reason: "reachability restored")
    }

    func handleAuthStateUpdate(_ state: AuthState) async {
        guard state == .unauthenticated, currentFlow == .main else { return }

        Self.logger.info("auth state became unauthenticated while main flow is active. switching to authentication flow.")

        showAuthenticationFlow()

        Task {
            do {
                try await dependencies.unauthorizedSessionHandler.handleUnauthorizedSession()
            } catch {
                Self.logger.error(
                    "failed to clear local artifacts after unauthorized session. error='\(error.localizedDescription, privacy: .public)'"
                )
            }
        }
    }

    func showAuthenticationFlow() {
        guard currentFlow != .authentication else { return }

        currentFlow = .authentication
        let authFlow = dependencies.makeAuthFlow { [weak self] in
            self?.showMainFlow()
        }

        mainCoordinator = nil
        authCoordinator = authFlow.coordinator
        window.rootViewController = authFlow.rootViewController
        authFlow.coordinator.start()
    }

    func showMainFlow() {
        guard currentFlow != .main else { return }

        currentFlow = .main
        let coordinator = dependencies.makeMainCoordinator { [weak self] in
            self?.showAuthenticationFlow()
        }

        authCoordinator = nil
        mainCoordinator = coordinator
        window.rootViewController = coordinator.rootViewController
        coordinator.start()
        runSyncAfterAuthorization()
    }

    func runSyncAfterAuthorization() {
        runSync(trigger: .manual, reason: "authorization finished")
    }

    func runSync(trigger: SyncTrigger, reason: StaticString) {
        Task {
            Self.logger.info("starting sync. reason='\(reason, privacy: .public)'")
            do {
                _ = try await dependencies.syncService.run(trigger: trigger)
                Self.logger.info("sync finished successfully. reason='\(reason, privacy: .public)'")
            } catch SyncEngineError.alreadyRunning {
                Self.logger.info("sync skipped because engine is already running. reason='\(reason, privacy: .public)'")
            } catch SyncEngineError.networkUnavailable {
                Self.logger.info("sync skipped because network is unavailable. reason='\(reason, privacy: .public)'")
            } catch {
                Self.logger.error("sync failed. reason='\(reason, privacy: .public)' error='\(error.localizedDescription, privacy: .public)'")
            }
        }
    }
}
