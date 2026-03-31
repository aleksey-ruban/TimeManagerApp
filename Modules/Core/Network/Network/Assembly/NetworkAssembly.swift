import Foundation

public protocol NetworkAssemblyProtocol: Sendable {
    func makeExecutorFactory() -> NetworkExecutorFactoryProtocol
}

public struct NetworkAssembly: NetworkAssemblyProtocol {
    
    private let authInterceptor: AuthInterceptorProtocol?
    
    public init(authInterceptor: AuthInterceptorProtocol?) {
        self.authInterceptor = authInterceptor
    }
    
    public func makeExecutorFactory() -> NetworkExecutorFactoryProtocol {
        let session = NetworkSessionFactory.makeDefault()
        let transportClient = URLSessionNetworkClient(session: session)
        let networkClient = RetryingNetworkClient(nextClient: transportClient)

        return NetworkExecutorFactory(
            networkClient: networkClient,
            authInterceptor: authInterceptor
        )
    }
}
