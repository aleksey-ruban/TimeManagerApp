import Foundation

public protocol NetworkClientProtocol: Sendable {
    func execute(_ request: NetworkRequest) async throws -> NetworkResponse
}
