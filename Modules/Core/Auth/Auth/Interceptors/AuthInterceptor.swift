import Foundation
import CoreNetwork

final class AuthInterceptor: AuthInterceptorProtocol, @unchecked Sendable {
    private let authSession: AuthSessionProtocol
    private let lock = NSLock()
    private var nextClient: NetworkClientProtocol?

    init(authSession: AuthSessionProtocol) {
        self.authSession = authSession
    }

    func setNextClient(_ client: NetworkClientProtocol) {
        lock.lock()
        nextClient = client
        lock.unlock()
    }

    func execute(_ request: NetworkRequest) async throws -> NetworkResponse {
        let client = try currentNextClient()

        guard request.requiresAuthorization else {
            return try await client.execute(request)
        }

        let authorizedRequest = try await authSession.authorize(request)

        do {
            return try await client.execute(authorizedRequest)
        } catch let error as NetworkError where error.statusCode == 401 {
            let recoveredRequest = try await authSession.recoverAuthorization(for: authorizedRequest)
            return try await client.execute(recoveredRequest)
        }
    }

    private func currentNextClient() throws -> NetworkClientProtocol {
        lock.lock()
        let client = nextClient
        lock.unlock()

        guard let client else {
            throw AuthError.missingNetworkClient
        }

        return client
    }
}

private extension NetworkError {
    var statusCode: Int? {
        guard case let .httpStatusCode(statusCode, _) = self else {
            return nil
        }

        return statusCode
    }
}
