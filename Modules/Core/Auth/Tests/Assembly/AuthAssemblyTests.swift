import Foundation
import XCTest
@testable import CoreAuth

final class AuthAssemblyTests: XCTestCase {
    func testAssemblyBuildsModuleWithUnauthenticatedInitialState() async throws {
        let assembly = AuthAssembly(
            configuration: AuthAPIConfiguration(baseURL: URL(string: "https://example.com")!),
            tokenStore: InMemoryTokenStore(),
            deviceIDStore: DeviceIDStoreStub(),
            deviceModelProvider: DeviceModelProviderStub()
        )

        let module = try assembly.makeModule()
        let state = await module.authStateProvider.authState()

        XCTAssertEqual(state, .unauthenticated)
    }
}
