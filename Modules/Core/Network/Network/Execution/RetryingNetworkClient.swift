import Foundation

final class RetryingNetworkClient: NetworkClientProtocol {
    private let nextClient: NetworkClientProtocol
    private let retryDelayStrategy: RetryDelayStrategyProtocol

    init(
        nextClient: NetworkClientProtocol,
        retryDelayStrategy: RetryDelayStrategyProtocol = ExponentialRetryDelayStrategy()
    ) {
        self.nextClient = nextClient
        self.retryDelayStrategy = retryDelayStrategy
    }

    func execute(_ request: NetworkRequest) async throws -> NetworkResponse {
        let maxRetries = request.retryPolicy.maxRetries
        let canRetryRequest = request.isRetryEligible
        var attempt = 0

        while true {
            do {
                return try await nextClient.execute(request)
            } catch let error as NetworkError {
                
                guard isRetryableError(
                    error,
                    maxRetries: maxRetries,
                    canRetryRequest: canRetryRequest,
                    attempt: attempt
                ) else {
                    throw error
                }

                attempt += 1
                try await Task.sleep(for: retryDelayStrategy.delay(forAttempt: attempt))
            } catch {
                let mappedError = NetworkErrorMapper.map(error)
                
                guard isRetryableError(
                    mappedError,
                    maxRetries: maxRetries,
                    canRetryRequest: canRetryRequest,
                    attempt: attempt
                ) else {
                    throw error
                }

                attempt += 1
                try await Task.sleep(for: retryDelayStrategy.delay(forAttempt: attempt))
            }
        }
    }
    
    private func isRetryableError(
        _ error: NetworkError,
        maxRetries: Int,
        canRetryRequest: Bool,
        attempt: Int
    ) -> Bool {
        error.isRetryable && canRetryRequest && attempt < maxRetries
    }
}
