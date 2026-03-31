import Foundation

public enum AuthError: Error, Equatable {
    case manualAuthorizationRequired
    case missingNetworkClient
    case invalidAuthResponse
}
