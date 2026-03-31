import Foundation

protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

final class URLSessionNetworkClient: NetworkClientProtocol {
    private let session: URLSessionProtocol
    private let requestBuilder: RequestBuilding

    init(
        session: URLSessionProtocol = URLSession.shared,
        requestBuilder: RequestBuilding = RequestBuilder()
    ) {
        self.session = session
        self.requestBuilder = requestBuilder
    }

    func execute(_ request: NetworkRequest) async throws -> NetworkResponse {
        let urlRequest: URLRequest

        do {
            urlRequest = try requestBuilder.build(from: request)
        } catch {
            throw NetworkErrorMapper.map(error)
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200 ... 299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpStatusCode(httpResponse.statusCode, data)
            }

            return NetworkResponse(data: data, response: httpResponse)
        } catch {
            throw NetworkErrorMapper.map(error)
        }
    }
}
