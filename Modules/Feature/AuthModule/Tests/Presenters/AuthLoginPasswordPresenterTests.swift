import XCTest
@testable import FeatureAuthModule

@MainActor
final class AuthLoginPasswordPresenterTests: XCTestCase {
    func testDidTapLoginAuthorizesWithCoreAuth() async {
        let flowService = AuthFlowServiceSpy()
        let authService = AuthFeatureServiceSpy()
        var authorized = false
        let presenter = AuthLoginPasswordPresenter(
            email: "user@example.com",
            flowService: flowService,
            authFeatureService: authService,
            localeProvider: AuthLocaleProviderStub(value: "ru"),
            onStartPasswordReset: { _, _ in XCTFail("unexpected reset route") },
            onAuthorized: { authorized = true }
        )
        let view = AuthLoginPasswordViewSpy()
        presenter.view = view
        presenter.viewDidLoad()
        presenter.didUpdatePassword("secret1")

        presenter.didTapLogin()
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(authService.loginArguments?.email, "user@example.com")
        XCTAssertEqual(authService.loginArguments?.password, "secret1")
        XCTAssertTrue(authorized)
        XCTAssertEqual(view.loadingStates, [true, false])
    }

    func testDidTapForgotPasswordStartsResetFlow() async {
        let flowService = AuthFlowServiceSpy()
        flowService.startPasswordResetResult = .success(
            AuthCodeDeliveryResponse(message: "", expiresAt: "2026-02-02T00:00:00Z")
        )
        var routed: (String, String?)?
        let presenter = AuthLoginPasswordPresenter(
            email: "user@example.com",
            flowService: flowService,
            authFeatureService: AuthFeatureServiceSpy(),
            localeProvider: AuthLocaleProviderStub(value: "ru"),
            onStartPasswordReset: { email, expiresAt in routed = (email, expiresAt) },
            onAuthorized: {}
        )
        let view = AuthLoginPasswordViewSpy()
        presenter.view = view

        presenter.didTapForgotPassword()
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(flowService.startedEmail, "user@example.com")
        XCTAssertEqual(flowService.startedLocale, "ru")
        XCTAssertEqual(routed?.0, "user@example.com")
        XCTAssertEqual(routed?.1, "2026-02-02T00:00:00Z")
    }
}
