import Foundation

public protocol INetworkExecutor: Sendable {
    func execute<Output: Decodable>(
        _ request: NetworkRequest,
        parser: Parser<Output>
    ) async throws -> Output
}

final class NetworkExecutor: INetworkExecutor {
    private let client: NetworkClientProtocol

    init(client: NetworkClientProtocol) {
        self.client = client
    }

    func execute<Output: Decodable>(
        _ request: NetworkRequest,
        parser: Parser<Output>
    ) async throws -> Output {
        let response = try await client.execute(request)
        return try parser.parse(response.data)
    }
}
