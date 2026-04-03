import Foundation
import CoreNetwork

struct NetworkAuthFlowService: AuthFlowServiceProtocol {
    private let networkExecutorFactory: NetworkExecutorFactoryProtocol
    private let configuration: AuthFeatureAPIConfiguration
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    init(
        networkExecutorFactory: NetworkExecutorFactoryProtocol,
        configuration: AuthFeatureAPIConfiguration,
        jsonDecoder: JSONDecoder = JSONDecoder(),
        jsonEncoder: JSONEncoder = JSONEncoder()
    ) {
        self.networkExecutorFactory = networkExecutorFactory
        self.configuration = configuration
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
    }

    func start(email: String, locale: String) async throws -> AuthStartResponse {
        let payload = try await execute(
            path: configuration.startPath,
            body: EmailStartRequest(email: email, local: locale),
            responseType: StartResponsePayload.self
        )

        return AuthStartResponse(
            action: payload.action,
            message: payload.message,
            expiresAt: payload.expiresAt
        )
    }

    func verifyRegistrationCode(email: String, code: String) async throws {
        _ = try await execute(
            path: configuration.registrationVerifyPath,
            body: VerificationCodeRequest(email: email, code: code),
            responseType: MessageResponsePayload.self
        )
    }

    func resendRegistrationCode(email: String, locale: String) async throws {
        _ = try await execute(
            path: configuration.registrationResendPath,
            body: EmailStartRequest(email: email, local: locale),
            responseType: MessageResponsePayload.self
        )
    }

    func completeRegistration(email: String, firstName: String, password: String) async throws {
        _ = try await execute(
            path: configuration.registrationCompletePath,
            body: RegistrationCompleteRequest(
                email: email,
                firstName: firstName,
                password: password
            ),
            responseType: MessageResponsePayload.self
        )
    }

    func startPasswordReset(email: String, locale: String) async throws -> AuthCodeDeliveryResponse {
        let payload = try await execute(
            path: configuration.passwordResetStartPath,
            body: EmailStartRequest(email: email, local: locale),
            responseType: CodeDeliveryResponsePayload.self
        )

        return AuthCodeDeliveryResponse(
            message: payload.message,
            expiresAt: payload.expiresAt
        )
    }

    func resendPasswordResetCode(email: String, locale: String) async throws {
        _ = try await execute(
            path: configuration.passwordResetResendPath,
            body: EmailStartRequest(email: email, local: locale),
            responseType: MessageResponsePayload.self
        )
    }

    func verifyPasswordResetCode(email: String, code: String) async throws {
        _ = try await execute(
            path: configuration.passwordResetVerifyPath,
            body: VerificationCodeRequest(email: email, code: code),
            responseType: MessageResponsePayload.self
        )
    }

    func completePasswordReset(email: String, newPassword: String, deviceID: String) async throws {
        _ = try await execute(
            path: configuration.passwordResetCompletePath,
            body: PasswordResetCompleteRequest(
                email: email,
                newPassword: newPassword,
                deviceId: deviceID
            ),
            responseType: MessageResponsePayload.self
        )
    }

    private func execute<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body,
        responseType: Response.Type
    ) async throws -> Response {
        let request = try makeRequest(path: path, body: body)
        let executor = networkExecutorFactory.makeExecutor()
        let parser = Parser<Response>(decoder: jsonDecoder)
        return try await executor.execute(request, parser: parser)
    }

    private func makeRequest<Body: Encodable>(path: String, body: Body) throws -> NetworkRequest {
        let bodyData = try jsonEncoder.encode(body)

        return NetworkRequest(
            method: .post,
            baseURL: configuration.baseURL,
            path: path,
            headers: [
                "Accept": "application/json",
            ],
            body: .data(bodyData, contentType: "application/json"),
            allowsCookies: true,
            retryPolicy: .none,
            idempotency: .unsafe
        )
    }
}

struct AuthStartResponse: Sendable, Equatable {
    let action: AuthStartAction
    let message: String
    let expiresAt: String?
}

struct AuthCodeDeliveryResponse: Sendable, Equatable {
    let message: String
    let expiresAt: String?
}

enum AuthStartAction: String, Decodable, Sendable {
    case registration
    case login
}

private struct EmailStartRequest: Encodable {
    let email: String
    let local: String
}

private struct VerificationCodeRequest: Encodable {
    let email: String
    let code: String
}

private struct RegistrationCompleteRequest: Encodable {
    let email: String
    let firstName: String
    let password: String
}

private struct PasswordResetCompleteRequest: Encodable {
    let email: String
    let newPassword: String
    let deviceId: String
}

private struct StartResponsePayload: Decodable {
    let action: AuthStartAction
    let message: String
    let expiresAt: String?
}

private struct MessageResponsePayload: Decodable {
    let message: String
}

private struct CodeDeliveryResponsePayload: Decodable {
    let message: String
    let expiresAt: String?
}
