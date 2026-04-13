import XCTest
@testable import FeatureAuthModule

@MainActor
final class AuthRegistrationPresenterTests: XCTestCase {
    func testDidTapContinueCompletesRegistrationAndLogsIn() async {
        let flowService = AuthFlowServiceSpy()
        let authService = AuthFeatureServiceSpy()
        var authorized = false
        let presenter = AuthRegistrationPresenter(
            email: "user@example.com",
            flowService: flowService,
            authFeatureService: authService,
            onAuthorized: { authorized = true }
        )
        let view = AuthRegistrationViewSpy()
        presenter.view = view
        presenter.viewDidLoad()
        presenter.didUpdateFirstName("Alex")
        presenter.didUpdatePassword("secret1")

        presenter.didTapContinue()
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(flowService.completedRegistration?.email, "user@example.com")
        XCTAssertEqual(flowService.completedRegistration?.firstName, "Alex")
        XCTAssertEqual(flowService.completedRegistration?.password, "secret1")
        XCTAssertEqual(authService.loginArguments?.email, "user@example.com")
        XCTAssertEqual(authService.loginArguments?.password, "secret1")
        XCTAssertTrue(authorized)
    }
}
