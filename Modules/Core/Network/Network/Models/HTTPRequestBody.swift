import Foundation

public enum HTTPRequestBody: Sendable, Equatable {
    case data(Data, contentType: String? = nil)

    public var data: Data {
        switch self {
        case let .data(data, _):
            return data
        }
    }

    public var contentType: String? {
        switch self {
        case let .data(_, contentType):
            return contentType
        }
    }
}
