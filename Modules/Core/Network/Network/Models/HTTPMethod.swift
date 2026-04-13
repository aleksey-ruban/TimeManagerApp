import Foundation

public enum HTTPMethod: String, CaseIterable, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
    case trace = "TRACE"
    case connect = "CONNECT"

    var isRetrySafeByDefault: Bool {
        switch self {
        case .get, .head, .options, .trace:
            return true
        case .post, .put, .patch, .delete, .connect:
            return false
        }
    }
}
