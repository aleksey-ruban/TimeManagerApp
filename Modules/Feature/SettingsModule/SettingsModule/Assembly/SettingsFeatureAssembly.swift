import CoreSessionCleanup
import CoreUserProfile
import CoreAuth
import UIKit

public protocol SettingsFeatureAssemblyProtocol: Sendable {
    @MainActor
    func makeCoordinator(
        navigationController: UINavigationController,
        onSessionFinished: @escaping @MainActor () -> Void
    ) -> SettingsCoordinatorProtocol
}

public struct SettingsFeatureAssembly: SettingsFeatureAssemblyProtocol, @unchecked Sendable {
    private let userProfileService: UserProfileServiceProtocol
    private let authFeatureService: AuthFeatureServiceProtocol
    private let sessionCleanupService: SessionCleanupServiceProtocol

    public init(
        userProfileService: UserProfileServiceProtocol,
        authFeatureService: AuthFeatureServiceProtocol,
        sessionCleanupService: SessionCleanupServiceProtocol
    ) {
        self.userProfileService = userProfileService
        self.authFeatureService = authFeatureService
        self.sessionCleanupService = sessionCleanupService
    }

    @MainActor
    public func makeCoordinator(
        navigationController: UINavigationController,
        onSessionFinished: @escaping @MainActor () -> Void
    ) -> SettingsCoordinatorProtocol {
        let service = SettingsFeatureService(
            userProfileService: userProfileService,
            authFeatureService: authFeatureService,
            sessionCleanupService: sessionCleanupService
        )

        return SettingsCoordinator(
            navigationController: navigationController,
            rootAssembly: SettingsRootAssembly(service: service),
            profileEditAssembly: SettingsProfileEditAssembly(service: service),
            securityAssembly: SettingsSecurityAssembly(service: service),
            onSessionFinished: onSessionFinished
        )
    }
}
