import Foundation
import CoreNetwork

enum AuthFeatureErrorFormatter {
    static func message(for error: Error) -> String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case let .httpStatusCode(statusCode, data):
                if
                    let payload = try? JSONDecoder().decode(AuthErrorPayload.self, from: data),
                    payload.message.isEmpty == false
                {
                    return payload.message
                }

                return "Request failed with status code \(statusCode)."
            case let .transportError(message, _):
                return message
            case .invalidResponse:
                return "Invalid server response."
            case let .invalidURL(path):
                return "Invalid request path: \(path)."
            }
        }

        return error.localizedDescription
    }
}

private struct AuthErrorPayload: Decodable {
    let message: String
}
