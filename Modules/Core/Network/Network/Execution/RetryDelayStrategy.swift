import Foundation

protocol RetryDelayStrategyProtocol: Sendable {
    func delay(forAttempt attempt: Int) -> Duration
}

struct ExponentialRetryDelayStrategy: RetryDelayStrategyProtocol {
    private let baseDelayMilliseconds: Int

    init(baseDelayMilliseconds: Int = 300) {
        self.baseDelayMilliseconds = baseDelayMilliseconds
    }

    func delay(forAttempt attempt: Int) -> Duration {
        let multiplier = 1 << max(0, attempt - 1)
        return .milliseconds(baseDelayMilliseconds * multiplier)
    }
}
