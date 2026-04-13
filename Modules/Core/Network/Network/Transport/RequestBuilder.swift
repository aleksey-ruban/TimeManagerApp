import Foundation

protocol RequestBuilding: Sendable {
    func build(from request: NetworkRequest) throws -> URLRequest
}

struct RequestBuilder: RequestBuilding {
    func build(from request: NetworkRequest) throws -> URLRequest {
        guard var components = URLComponents(
            url: request.baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL(path: request.path)
        }

        if request.queryItems.isEmpty == false {
            components.queryItems = request.queryItems
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL(path: request.path)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue

        if let timeoutInterval = request.timeoutInterval {
            urlRequest.timeoutInterval = timeoutInterval
        }

        if let cachePolicy = request.cachePolicy {
            urlRequest.cachePolicy = cachePolicy
        }

        if let allowsCookies = request.allowsCookies {
            urlRequest.httpShouldHandleCookies = allowsCookies
        }

        request.headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if case let .data(data, contentType)? = request.body {
            urlRequest.httpBody = data

            if let contentType, request.headers["Content-Type"] == nil {
                urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
            }
        }

        switch request.idempotency {
        case let .key(key):
            if request.headers["Idempotency-Key"] == nil {
                urlRequest.setValue(key, forHTTPHeaderField: "Idempotency-Key")
            }
        case .inherited, .retrySafe, .unsafe:
            break
        }

        return urlRequest
    }
}
