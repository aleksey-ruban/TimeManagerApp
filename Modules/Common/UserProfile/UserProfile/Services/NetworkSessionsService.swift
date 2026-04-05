import CoreNetwork
import Domain
import Foundation

actor NetworkSessionsService {
    private let executorFactory: NetworkExecutorFactoryProtocol
    private let configuration: UserProfileAPIConfiguration
    private let decoder: JSONDecoder

    init(
        executorFactory: NetworkExecutorFactoryProtocol,
        configuration: UserProfileAPIConfiguration
    ) {
        self.executorFactory = executorFactory
        self.configuration = configuration

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(ServerDateDecoder.decode)
        self.decoder = decoder
    }

    func fetchSessions() async throws -> UserSessions {
        let executor = executorFactory.makeExecutor()
        let request = NetworkRequest(
            method: .get,
            baseURL: configuration.baseURL,
            path: configuration.sessionsPath,
            cachePolicy: .reloadIgnoringLocalCacheData,
            requiresAuthorization: true
        )

        return try await executor.execute(
            request,
            parser: Parser<UserSessions>(decoder: decoder)
        )
    }
}
