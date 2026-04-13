import XCTest
@testable import FeatureAuthModule

@MainActor
final class AuthPasswordResetPresenterTests: XCTestCase {
    func testDidTapContinueCompletesPasswordResetAndLogsIn() async {
        let flowService = AuthFlowServiceSpy()
        let authService = AuthFeatureServiceSpy()
        authService.currentDeviceIDResult = .success("device-42")
        var authorized = false
        let presenter = AuthPasswordResetPresenter(
            email: "user@example.com",
            flowService: flowService,
            authFeatureService: authService,
            onAuthorized: { authorized = true }
        )
        let view = AuthPasswordResetViewSpy()
        presenter.view = view
        presenter.viewDidLoad()
        presenter.didUpdatePassword("secret1")

        presenter.didTapContinue()
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(flowService.completedPasswordReset?.email, "user@example.com")
        XCTAssertEqual(flowService.completedPasswordReset?.password, "secret1")
        XCTAssertEqual(flowService.completedPasswordReset?.deviceID, "device-42")
        XCTAssertEqual(authService.loginArguments?.email, "user@example.com")
        XCTAssertTrue(authorized)
    }
}
