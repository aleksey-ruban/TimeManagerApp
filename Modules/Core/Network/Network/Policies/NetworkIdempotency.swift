import Foundation

public enum NetworkIdempotency: Sendable, Equatable {
    case inherited
    case retrySafe
    case unsafe
    case key(String)
}
