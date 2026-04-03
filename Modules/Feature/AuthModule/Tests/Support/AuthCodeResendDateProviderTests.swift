import XCTest
@testable import FeatureAuthModule

final class AuthCodeResendDateProviderTests: XCTestCase {
    func testMakeResendAvailableAtAddsAboutOneMinute() {
        let provider = DefaultAuthCodeResendDateProvider()
        let now = Date()

        let value = provider.makeResendAvailableAt()

        XCTAssertEqual(value.timeIntervalSince(now), 60, accuracy: 1.0)
    }
}
