import Foundation

public struct NetworkRequest: Sendable, Equatable {
    public let method: HTTPMethod
    public let baseURL: URL
    public let path: String
    public let headers: [String: String]
    public let queryItems: [URLQueryItem]
    public let body: HTTPRequestBody?
    public let timeoutInterval: TimeInterval?
    public let cachePolicy: URLRequest.CachePolicy?
    public let allowsCookies: Bool?
    public let requiresAuthorization: Bool
    public let retryPolicy: NetworkRetryPolicy
    public let idempotency: NetworkIdempotency

    public init(
        method: HTTPMethod,
        baseURL: URL,
        path: String,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        body: HTTPRequestBody? = nil,
        timeoutInterval: TimeInterval? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        allowsCookies: Bool? = nil,
        requiresAuthorization: Bool = false,
        retryPolicy: NetworkRetryPolicy = .none,
        idempotency: NetworkIdempotency = .inherited
    ) {
        self.method = method
        self.baseURL = baseURL
        self.path = path
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
        self.timeoutInterval = timeoutInterval
        self.cachePolicy = cachePolicy
        self.allowsCookies = allowsCookies
        self.requiresAuthorization = requiresAuthorization
        self.retryPolicy = retryPolicy
        self.idempotency = idempotency
    }

    public func addingHeader(name: String, value: String) -> NetworkRequest {
        var headers = headers
        headers[name] = value

        return NetworkRequest(
            method: method,
            baseURL: baseURL,
            path: path,
            headers: headers,
            queryItems: queryItems,
            body: body,
            timeoutInterval: timeoutInterval,
            cachePolicy: cachePolicy,
            allowsCookies: allowsCookies,
            requiresAuthorization: requiresAuthorization,
            retryPolicy: retryPolicy,
            idempotency: idempotency
        )
    }

    var isRetryEligible: Bool {
        switch retryPolicy {
        case .none:
            return false
        case .safeMethods, .custom:
            break
        }

        switch idempotency {
        case .retrySafe, .key:
            return true
        case .unsafe:
            return false
        case .inherited:
            return method.isRetrySafeByDefault
        }
    }
}
