import Foundation

public protocol NetworkExecutorFactoryProtocol: Sendable {
    func makeExecutor() -> INetworkExecutor
}

final class NetworkExecutorFactory: NetworkExecutorFactoryProtocol {
    private let networkClient: NetworkClientProtocol
    private let authInterceptor: AuthInterceptorProtocol?

    init(
        networkClient: NetworkClientProtocol,
        authInterceptor: AuthInterceptorProtocol?
    ) {
        self.networkClient = networkClient
        self.authInterceptor = authInterceptor
    }

    func makeExecutor() -> INetworkExecutor {
        if let authInterceptor {
            authInterceptor.setNextClient(networkClient)
            return NetworkExecutor(client: authInterceptor)
        }

        return NetworkExecutor(client: networkClient)
    }
}
