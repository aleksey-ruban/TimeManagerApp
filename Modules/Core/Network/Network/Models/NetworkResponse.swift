import Foundation

public struct NetworkResponse: Sendable {
    public let data: Data
    public let response: HTTPURLResponse

    public init(data: Data, response: HTTPURLResponse) {
        self.data = data
        self.response = response
    }

    public var statusCode: Int {
        response.statusCode
    }

    public var headers: [AnyHashable: Any] {
        response.allHeaderFields
    }
}
