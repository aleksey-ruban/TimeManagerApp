import Foundation

public enum NetworkRetryPolicy: Sendable, Equatable {
    case none
    case safeMethods
    case custom(maxRetries: Int)

    var maxRetries: Int {
        switch self {
        case .none:
            return 0
        case .safeMethods:
            return 3
        case let .custom(maxRetries):
            return max(0, maxRetries)
        }
    }
}
