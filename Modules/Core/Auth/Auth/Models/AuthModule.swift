import Foundation
import CoreNetwork

public struct AuthModule: Sendable {
    public let authStateProvider: AuthStateProviderProtocol
    public let authFeatureService: AuthFeatureServiceProtocol
    public let authInterceptor: AuthInterceptorProtocol

    init(
        authStateProvider: AuthStateProviderProtocol,
        authFeatureService: AuthFeatureServiceProtocol,
        authInterceptor: AuthInterceptorProtocol
    ) {
        self.authStateProvider = authStateProvider
        self.authFeatureService = authFeatureService
        self.authInterceptor = authInterceptor
    }
}
