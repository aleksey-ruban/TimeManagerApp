import CoreNetwork
import Domain
import Foundation

actor NetworkProfileService {
    private let executorFactory: NetworkExecutorFactoryProtocol
    private let configuration: UserProfileAPIConfiguration
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        executorFactory: NetworkExecutorFactoryProtocol,
        configuration: UserProfileAPIConfiguration
    ) {
        self.executorFactory = executorFactory
        self.configuration = configuration

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(ServerDateDecoder.decode)
        self.decoder = decoder
        self.encoder = JSONEncoder()
    }

    func fetchUser() async throws -> UserResponseDTO {
        let executor = executorFactory.makeExecutor()
        let request = NetworkRequest(
            method: .get,
            baseURL: configuration.baseURL,
            path: configuration.userPath,
            cachePolicy: .reloadIgnoringLocalCacheData,
            requiresAuthorization: true
        )

        return try await executor.execute(
            request,
            parser: Parser<UserResponseDTO>(decoder: decoder)
        )
    }

    func updateProfile(name: String) async throws -> UserResponseDTO {
        let executor = executorFactory.makeExecutor()
        let request = try makeRequest(
            method: .patch,
            path: configuration.updateProfilePath,
            body: UpdateProfileRequestBody(name: name)
        )

        return try await executor.execute(
            request,
            parser: Parser<UserResponseDTO>(decoder: decoder)
        )
    }

    func deleteUser() async throws {
        let executor = executorFactory.makeExecutor()
        let request = NetworkRequest(
            method: .delete,
            baseURL: configuration.baseURL,
            path: configuration.userPath,
            headers: [
                "Accept": "application/json",
            ],
            requiresAuthorization: true,
            retryPolicy: .none
        )

        _ = try await executor.execute(request)
    }

    private func makeRequest<Body: Encodable>(
        method: HTTPMethod,
        path: String,
        body: Body
    ) throws -> NetworkRequest {
        let bodyData = try encoder.encode(body)
        return NetworkRequest(
            method: method,
            baseURL: configuration.baseURL,
            path: path,
            headers: [
                "Accept": "application/json",
            ],
            body: .data(bodyData, contentType: "application/json"),
            requiresAuthorization: true,
            retryPolicy: .none,
            idempotency: .key(UUID().uuidString.lowercased())
        )
    }
}

private struct UpdateProfileRequestBody: Encodable {
    let name: String
}
