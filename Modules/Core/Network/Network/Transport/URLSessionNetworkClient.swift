import Foundation

protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

final class URLSessionNetworkClient: NetworkClientProtocol {
    private let session: URLSessionProtocol
    private let requestBuilder: RequestBuilding
    private let logger: NetworkLogging

    init(
        session: URLSessionProtocol = URLSession.shared,
        requestBuilder: RequestBuilding = RequestBuilder(),
        logger: NetworkLogging = NetworkLogger(configuration: .disabled)
    ) {
        self.session = session
        self.requestBuilder = requestBuilder
        self.logger = logger
    }

    func execute(_ request: NetworkRequest) async throws -> NetworkResponse {
        let urlRequest: URLRequest

        do {
            urlRequest = try requestBuilder.build(from: request)
        } catch {
            throw NetworkErrorMapper.map(error)
        }

        logger.logRequest(urlRequest)

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            logger.logResponse(data: data, response: httpResponse, for: urlRequest)

            guard (200 ... 299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpStatusCode(httpResponse.statusCode, data)
            }

            return NetworkResponse(data: data, response: httpResponse)
        } catch {
            throw NetworkErrorMapper.map(error)
        }
    }
}
