import XCTest
@testable import FeatureAuthModule

@MainActor
final class AuthCodeVerificationPresenterTests: XCTestCase {
    func testViewDidLoadShowsCooldownTitleWhenResendUnavailable() {
        let presenter = AuthCodeVerificationPresenter(
            flow: .registration,
            email: "user@example.com",
            resendAvailableAt: Date().addingTimeInterval(30),
            flowService: AuthFlowServiceSpy(),
            localeProvider: AuthLocaleProviderStub(value: "ru"),
            onClose: {},
            onVerified: { _ in }
        )
        let view = AuthCodeVerificationViewSpy()
        presenter.view = view

        presenter.viewDidLoad()

        XCTAssertEqual(view.buttonUpdates.last?.isEnabled, false)
        XCTAssertTrue(view.buttonUpdates.last?.title.contains("Запросить через") == true)
    }

    func testDidTapPrimaryActionWithCodeVerifiesAndRoutesForward() async {
        let flowService = AuthFlowServiceSpy()
        var verifiedEmail: String?
        let presenter = AuthCodeVerificationPresenter(
            flow: .registration,
            email: "user@example.com",
            resendAvailableAt: nil,
            flowService: flowService,
            localeProvider: AuthLocaleProviderStub(value: "ru"),
            onClose: {},
            onVerified: { verifiedEmail = $0 }
        )
        let view = AuthCodeVerificationViewSpy()
        presenter.view = view
        presenter.didUpdateCode("123456")

        presenter.didTapPrimaryAction()
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(flowService.verifiedRegistrationCode?.email, "user@example.com")
        XCTAssertEqual(flowService.verifiedRegistrationCode?.code, "123456")
        XCTAssertEqual(verifiedEmail, "user@example.com")
    }

    func testDidTapPrimaryActionWithoutCodeResendsCode() async {
        let flowService = AuthFlowServiceSpy()
        let presenter = AuthCodeVerificationPresenter(
            flow: .passwordReset,
            email: "user@example.com",
            resendAvailableAt: nil,
            flowService: flowService,
            localeProvider: AuthLocaleProviderStub(value: "ru"),
            onClose: {},
            onVerified: { _ in }
        )
        let view = AuthCodeVerificationViewSpy()
        presenter.view = view

        presenter.didTapPrimaryAction()
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(flowService.resentPasswordResetCode?.email, "user@example.com")
        XCTAssertEqual(flowService.resentPasswordResetCode?.locale, "ru")
    }
}
