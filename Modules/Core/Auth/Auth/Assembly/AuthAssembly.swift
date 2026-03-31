import Foundation
import CoreNetwork

protocol AuthAssemblyProtocol: Sendable {
    func makeModule() throws -> AuthModule
}

public struct AuthAssembly: AuthAssemblyProtocol {
    private let configuration: AuthAPIConfiguration
    private let tokenStore: TokenStoreProtocol
    private let deviceIDStore: DeviceIDStoreProtocol
    private let deviceModelProvider: DeviceModelProviderProtocol

    public init(configuration: AuthAPIConfiguration) {
        self.configuration = configuration
        self.tokenStore = KeychainTokenStore()
        self.deviceIDStore = KeychainDeviceIDStore()
        self.deviceModelProvider = SystemDeviceModelProvider()
    }

    init(
        configuration: AuthAPIConfiguration,
        tokenStore: TokenStoreProtocol,
        deviceIDStore: DeviceIDStoreProtocol,
        deviceModelProvider: DeviceModelProviderProtocol
    ) {
        self.configuration = configuration
        self.tokenStore = tokenStore
        self.deviceIDStore = deviceIDStore
        self.deviceModelProvider = deviceModelProvider
    }

    public func makeModule() throws -> AuthModule {
        let authNetworkExecutorFactory = NetworkAssembly(authInterceptor: nil).makeExecutorFactory()
        let apiService = NetworkAuthAPIService(
            networkExecutorFactory: authNetworkExecutorFactory,
            configuration: configuration,
            deviceIDStore: deviceIDStore,
            deviceModelProvider: deviceModelProvider
        )
        let authService = try AuthService(
            tokenStore: tokenStore,
            apiService: apiService
        )
        let authInterceptor = AuthInterceptor(authSession: authService)

        return AuthModule(
            authStateProvider: authService,
            authFeatureService: authService,
            authInterceptor: authInterceptor
        )
    }
}
