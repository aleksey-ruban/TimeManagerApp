import CoreNetwork
import Foundation

public protocol CommonUserProfileAssemblyProtocol {
    func makeService() -> UserProfileServiceProtocol
}

public struct CommonUserProfileAssembly: CommonUserProfileAssemblyProtocol, @unchecked Sendable {
    private let networkExecutorFactory: NetworkExecutorFactoryProtocol
    private let configuration: UserProfileAPIConfiguration
    private let defaults: UserDefaults

    public init(
        networkExecutorFactory: NetworkExecutorFactoryProtocol,
        configuration: UserProfileAPIConfiguration,
        defaults: UserDefaults = .standard
    ) {
        self.networkExecutorFactory = networkExecutorFactory
        self.configuration = configuration
        self.defaults = defaults
    }

    public func makeService() -> UserProfileServiceProtocol {
        DefaultUserProfileService(
            profileService: NetworkProfileService(
                executorFactory: networkExecutorFactory,
                configuration: configuration
            ),
            sessionsService: NetworkSessionsService(
                executorFactory: networkExecutorFactory,
                configuration: configuration
            ),
            cacheStore: UserProfileCacheStore(defaults: defaults)
        )
    }
}
