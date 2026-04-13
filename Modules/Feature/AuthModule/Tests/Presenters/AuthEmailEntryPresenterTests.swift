import XCTest
@testable import FeatureAuthModule

@MainActor
final class AuthEmailEntryPresenterTests: XCTestCase {
    func testDidUpdateEmailEnablesPrimaryActionForValidEmail() {
        let presenter = makePresenter()
        let view = AuthEmailEntryViewSpy()
        presenter.view = view

        presenter.didUpdateEmail("user@example.com")

        XCTAssertEqual(view.primaryEnabledStates.last, true)
    }

    func testDidTapContinueRoutesToRegistrationWhenStartReturnsRegistration() async {
        let flowService = AuthFlowServiceSpy()
        flowService.startResult = .success(
            AuthStartResponse(action: .registration, message: "", expiresAt: "2026-01-01T00:00:00Z")
        )
        var routed: (String, String?)?
        let presenter = AuthEmailEntryPresenter(
            flowService: flowService,
            localeProvider: AuthLocaleProviderStub(value: "ru"),
            onRouteToLogin: { _ in XCTFail("unexpected login route") },
            onRouteToRegistrationCode: { email, expiresAt in routed = (email, expiresAt) }
        )
        let view = AuthEmailEntryViewSpy()
        presenter.view = view
        presenter.didUpdateEmail("User@example.com")

        presenter.didTapContinue()
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(flowService.startedEmail, "user@example.com")
        XCTAssertEqual(flowService.startedLocale, "ru")
        XCTAssertEqual(routed?.0, "user@example.com")
        XCTAssertEqual(routed?.1, "2026-01-01T00:00:00Z")
        XCTAssertEqual(view.loadingStates, [true, false])
    }

    private func makePresenter() -> AuthEmailEntryPresenter {
        AuthEmailEntryPresenter(
            flowService: AuthFlowServiceSpy(),
            localeProvider: AuthLocaleProviderStub(value: "ru"),
            onRouteToLogin: { _ in },
            onRouteToRegistrationCode: { _, _ in }
        )
    }
}
