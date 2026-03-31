import Foundation
import CoreNetwork

protocol AuthSessionProtocol: AuthStateProviderProtocol {
    func authorize(_ request: NetworkRequest) async throws -> NetworkRequest
    func recoverAuthorization(for failedRequest: NetworkRequest) async throws -> NetworkRequest
}
