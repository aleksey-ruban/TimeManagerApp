import Foundation
import XCTest
@testable import CoreNetwork

final class NetworkExecutorFactoryTests: XCTestCase {
    func testNetworkExecutorFactoryWiresAuthInterceptorBeforeTransportClient() async throws {
        let transportClient = NetworkClientSpy(responseData: Data("{}".utf8))
        let authInterceptor = AuthInterceptorSpy()
        let factory = NetworkExecutorFactory(
            networkClient: transportClient,
            authInterceptor: authInterceptor
        )
        let executor = factory.makeExecutor()
        let request = NetworkRequest(
            method: .get,
            baseURL: URL(string: "https://example.com")!,
            path: "me",
            requiresAuthorization: true
        )

        _ = try await executor.execute(request, parser: Parser<EmptyPayload>())

        XCTAssertEqual(authInterceptor.forwardedRequests.count, 1)
        XCTAssertTrue(authInterceptor.nextClientWasSet)
        XCTAssertEqual(transportClient.executedRequests.count, 1)
    }

    func testNetworkAssemblyCreatesExecutorFactoryThatUsesAuthInterceptor() async throws {
        let authInterceptor = AuthInterceptorSpy(responseData: Data("{}".utf8))
        let assembly = NetworkAssembly(authInterceptor: authInterceptor)
        let executor = assembly.makeExecutorFactory().makeExecutor()
        let request = NetworkRequest(
            method: .get,
            baseURL: URL(string: "https://example.com")!,
            path: "profile",
            requiresAuthorization: true
        )

        _ = try await executor.execute(request, parser: Parser<EmptyPayload>())

        XCTAssertEqual(authInterceptor.forwardedRequests.count, 1)
        XCTAssertTrue(authInterceptor.nextClientWasSet)
    }
}
