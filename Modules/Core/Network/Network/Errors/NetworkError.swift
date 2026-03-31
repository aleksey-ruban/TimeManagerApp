import Foundation

public enum NetworkError: Error, Equatable {
    case invalidURL(path: String)
    case invalidResponse
    case transportError(String, isRetryable: Bool)
    case httpStatusCode(Int, Data)

    var isRetryable: Bool {
        switch self {
        case let .transportError(_, isRetryable):
            return isRetryable
        case let .httpStatusCode(statusCode, _):
            return Self.retryableStatusCodes.contains(statusCode)
        case .invalidURL, .invalidResponse:
            return false
        }
    }

    private static let retryableStatusCodes: Set<Int> = [
        408,
        425,
        429,
        500,
        502,
        503,
        504
    ]
}
