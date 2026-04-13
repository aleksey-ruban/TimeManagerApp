import Foundation
import CoreAuth
@testable import FeatureAuthModule

final class AuthFlowServiceSpy: AuthFlowServiceProtocol, @unchecked Sendable {
    var startResult: Result<AuthStartResponse, Error> = .success(
        AuthStartResponse(action: .login, message: "", expiresAt: nil)
    )
    var startPasswordResetResult: Result<AuthCodeDeliveryResponse, Error> = .success(
        AuthCodeDeliveryResponse(message: "", expiresAt: nil)
    )
    var completeRegistrationResult: Result<Void, Error> = .success(())
    var completePasswordResetResult: Result<Void, Error> = .success(())
    var verifyRegistrationCodeResult: Result<Void, Error> = .success(())
    var verifyPasswordResetCodeResult: Result<Void, Error> = .success(())
    var resendRegistrationCodeResult: Result<Void, Error> = .success(())
    var resendPasswordResetCodeResult: Result<Void, Error> = .success(())

    private(set) var startedEmail: String?
    private(set) var startedLocale: String?
    private(set) var completedRegistration: (email: String, firstName: String, password: String)?
    private(set) var completedPasswordReset: (email: String, password: String, deviceID: String)?
    private(set) var verifiedRegistrationCode: (email: String, code: String)?
    private(set) var verifiedPasswordResetCode: (email: String, code: String)?
    private(set) var resentRegistrationCode: (email: String, locale: String)?
    private(set) var resentPasswordResetCode: (email: String, locale: String)?

    func start(email: String, locale: String) async throws -> AuthStartResponse {
        startedEmail = email
        startedLocale = locale
        return try startResult.get()
    }

    func verifyRegistrationCode(email: String, code: String) async throws {
        verifiedRegistrationCode = (email, code)
        try verifyRegistrationCodeResult.get()
    }

    func resendRegistrationCode(email: String, locale: String) async throws {
        resentRegistrationCode = (email, locale)
        try resendRegistrationCodeResult.get()
    }

    func completeRegistration(email: String, firstName: String, password: String) async throws {
        completedRegistration = (email, firstName, password)
        try completeRegistrationResult.get()
    }

    func startPasswordReset(email: String, locale: String) async throws -> AuthCodeDeliveryResponse {
        startedEmail = email
        startedLocale = locale
        return try startPasswordResetResult.get()
    }

    func resendPasswordResetCode(email: String, locale: String) async throws {
        resentPasswordResetCode = (email, locale)
        try resendPasswordResetCodeResult.get()
    }

    func verifyPasswordResetCode(email: String, code: String) async throws {
        verifiedPasswordResetCode = (email, code)
        try verifyPasswordResetCodeResult.get()
    }

    func completePasswordReset(email: String, newPassword: String, deviceID: String) async throws {
        completedPasswordReset = (email, newPassword, deviceID)
        try completePasswordResetResult.get()
    }
}

final class AuthFeatureServiceSpy: AuthFeatureServiceProtocol, @unchecked Sendable {
    var loginResult: Result<Void, Error> = .success(())
    var currentDeviceIDResult: Result<String, Error> = .success("device-id")

    private(set) var loginArguments: (email: String, password: String)?

    func login(email: String, password: String) async throws {
        loginArguments = (email, password)
        try loginResult.get()
    }

    func acceptAuthenticatedSession(email: String, password: String, accessToken: String, refreshToken: String) async throws {}

    func currentDeviceID() async throws -> String {
        try currentDeviceIDResult.get()
    }

    func logout() async throws {}
}

struct AuthLocaleProviderStub: AuthLocaleProviding {
    let value: String

    func localeCode() -> String {
        value
    }
}

@MainActor
final class AuthEmailEntryViewSpy: AuthEmailEntryView {
    private(set) var primaryEnabledStates: [Bool] = []
    private(set) var loadingStates: [Bool] = []
    private(set) var errorMessages: [String] = []

    func setPrimaryActionEnabled(_ isEnabled: Bool) {
        primaryEnabledStates.append(isEnabled)
    }

    func setLoading(_ isLoading: Bool) {
        loadingStates.append(isLoading)
    }

    func showError(message: String) {
        errorMessages.append(message)
    }
}

@MainActor
final class AuthLoginPasswordViewSpy: AuthLoginPasswordView {
    private(set) var primaryEnabledStates: [Bool] = []
    private(set) var loadingStates: [Bool] = []
    private(set) var errorMessages: [String] = []

    func setPrimaryActionEnabled(_ isEnabled: Bool) {
        primaryEnabledStates.append(isEnabled)
    }

    func setLoading(_ isLoading: Bool) {
        loadingStates.append(isLoading)
    }

    func showError(message: String) {
        errorMessages.append(message)
    }
}

@MainActor
final class AuthRegistrationViewSpy: AuthRegistrationView {
    private(set) var primaryEnabledStates: [Bool] = []
    private(set) var loadingStates: [Bool] = []
    private(set) var errorMessages: [String] = []

    func setPrimaryActionEnabled(_ isEnabled: Bool) {
        primaryEnabledStates.append(isEnabled)
    }

    func setLoading(_ isLoading: Bool) {
        loadingStates.append(isLoading)
    }

    func showError(message: String) {
        errorMessages.append(message)
    }
}

@MainActor
final class AuthPasswordResetViewSpy: AuthPasswordResetView {
    private(set) var primaryEnabledStates: [Bool] = []
    private(set) var loadingStates: [Bool] = []
    private(set) var errorMessages: [String] = []

    func setPrimaryActionEnabled(_ isEnabled: Bool) {
        primaryEnabledStates.append(isEnabled)
    }

    func setLoading(_ isLoading: Bool) {
        loadingStates.append(isLoading)
    }

    func showError(message: String) {
        errorMessages.append(message)
    }
}

@MainActor
final class AuthCodeVerificationViewSpy: AuthCodeVerificationView {
    private(set) var buttonUpdates: [(title: String, isEnabled: Bool)] = []
    private(set) var loadingStates: [Bool] = []
    private(set) var errorMessages: [String] = []

    func updatePrimaryButton(title: String, isEnabled: Bool) {
        buttonUpdates.append((title, isEnabled))
    }

    func setLoading(_ isLoading: Bool) {
        loadingStates.append(isLoading)
    }

    func showError(message: String) {
        errorMessages.append(message)
    }
}

enum TestError: Error {
    case failed
}
