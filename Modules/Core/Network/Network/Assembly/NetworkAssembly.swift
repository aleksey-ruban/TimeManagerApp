import Foundation

public protocol NetworkAssemblyProtocol: Sendable {
    func makeExecutorFactory() -> NetworkExecutorFactoryProtocol
}

public struct NetworkAssembly: NetworkAssemblyProtocol {
    private let authInterceptor: AuthInterceptorProtocol?
    private let loggingConfiguration: NetworkLoggingConfiguration

    public init(
        authInterceptor: AuthInterceptorProtocol?,
        loggingConfiguration: NetworkLoggingConfiguration = .disabled
    ) {
        self.authInterceptor = authInterceptor
        self.loggingConfiguration = loggingConfiguration
    }

    public func makeExecutorFactory() -> NetworkExecutorFactoryProtocol {
        let session = NetworkSessionFactory.makeDefault()
        let logger = NetworkLogger(configuration: loggingConfiguration)
        let transportClient = URLSessionNetworkClient(session: session, logger: logger)
        let networkClient = RetryingNetworkClient(nextClient: transportClient)

        return NetworkExecutorFactory(
            networkClient: networkClient,
            authInterceptor: authInterceptor
        )
    }
}
