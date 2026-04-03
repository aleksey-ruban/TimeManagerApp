import UIKit
import CoreAuth
import CoreNetwork

public protocol AuthFeatureAssemblyProtocol: Sendable {
    @MainActor
    func makeModule() -> AuthFeatureModule
}

public struct AuthFeatureAssembly: AuthFeatureAssemblyProtocol {
    private let configuration: AuthFeatureAPIConfiguration
    private let networkExecutorFactory: NetworkExecutorFactoryProtocol
    private let authFeatureService: AuthFeatureServiceProtocol
    private let localeProvider: AuthLocaleProviding
    private let codeResendDateProvider: AuthCodeResendDateProviding
    private let onAuthorized: (@MainActor () -> Void)?

    public init(
        configuration: AuthFeatureAPIConfiguration,
        authFeatureService: AuthFeatureServiceProtocol,
        networkExecutorFactory: NetworkExecutorFactoryProtocol,
        onAuthorized: (@MainActor () -> Void)? = nil
    ) {
        self.configuration = configuration
        self.networkExecutorFactory = networkExecutorFactory
        self.authFeatureService = authFeatureService
        self.localeProvider = SystemAuthLocaleProvider()
        self.codeResendDateProvider = DefaultAuthCodeResendDateProvider()
        self.onAuthorized = onAuthorized
    }

    init(
        configuration: AuthFeatureAPIConfiguration,
        authFeatureService: AuthFeatureServiceProtocol,
        networkExecutorFactory: NetworkExecutorFactoryProtocol,
        localeProvider: AuthLocaleProviding,
        codeResendDateProvider: AuthCodeResendDateProviding = DefaultAuthCodeResendDateProvider(),
        onAuthorized: (@MainActor () -> Void)? = nil
    ) {
        self.configuration = configuration
        self.networkExecutorFactory = networkExecutorFactory
        self.authFeatureService = authFeatureService
        self.localeProvider = localeProvider
        self.codeResendDateProvider = codeResendDateProvider
        self.onAuthorized = onAuthorized
    }

    @MainActor
    public func makeModule() -> AuthFeatureModule {
        let flowService = NetworkAuthFlowService(
            networkExecutorFactory: networkExecutorFactory,
            configuration: configuration
        )
        let navigationController = UINavigationController()
        let coordinator = AuthCoordinator(
            navigationController: navigationController,
            flowService: flowService,
            authFeatureService: authFeatureService,
            localeProvider: localeProvider,
            codeResendDateProvider: codeResendDateProvider,
            onAuthorized: onAuthorized
        )

        return AuthFeatureModule(
            rootViewController: navigationController,
            coordinator: coordinator
        )
    }
}
