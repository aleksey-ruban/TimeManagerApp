import CoreNetwork
import Foundation
@testable import CommonUserProfile

extension UserDefaults: @retroactive @unchecked Sendable {}

final class NetworkExecutorStub: INetworkExecutor, @unchecked Sendable {
    let result: Result<Data, Error>
    private(set) var executedRequests: [NetworkRequest] = []

    init(result: Result<Data, Error>) {
        self.result = result
    }

    func execute<DecodedOutput: Decodable>(
        _ request: NetworkRequest,
        parser: Parser<DecodedOutput>
    ) async throws -> DecodedOutput {
        executedRequests.append(request)

        switch result {
        case let .success(data):
            return try parser.parse(data)
        case let .failure(error):
            throw error
        }
    }
}

final class NetworkExecutorFactoryStub: NetworkExecutorFactoryProtocol, @unchecked Sendable {
    private let executor: INetworkExecutor

    init(executor: INetworkExecutor) {
        self.executor = executor
    }

    func makeExecutor() -> INetworkExecutor {
        executor
    }
}

func makeTestDefaults() -> UserDefaults {
    let suiteName = "CommonUserProfileTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}
