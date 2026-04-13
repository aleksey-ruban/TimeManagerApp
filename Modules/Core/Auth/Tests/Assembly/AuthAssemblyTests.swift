import Foundation
import XCTest
import CoreNetwork
@testable import CoreAuth

final class AuthAssemblyTests: XCTestCase {
    func testAssemblyBuildsModuleWithUnauthenticatedInitialState() async throws {
        let networkExecutorFactory = NetworkAssembly(authInterceptor: nil).makeExecutorFactory()
        let assembly = AuthAssembly(
            configuration: AuthAPIConfiguration(baseURL: URL(string: "https://example.com")!),
            networkExecutorFactory: networkExecutorFactory,
            tokenStore: InMemoryTokenStore(),
            deviceIDStore: DeviceIDStoreStub(),
            deviceModelProvider: DeviceModelProviderStub(),
            sessionCleanupRegistry: AuthSessionCleanupRegistry()
        )

        let module = try assembly.makeModule()
        let state = await module.authStateProvider.authState()

        XCTAssertEqual(state, .unauthenticated)
    }
}
