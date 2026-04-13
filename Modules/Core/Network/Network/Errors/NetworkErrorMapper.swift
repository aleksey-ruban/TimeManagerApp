import Foundation

enum NetworkErrorMapper {
    static func map(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }

        if let urlError = error as? URLError {
            return .transportError(
                urlError.localizedDescription,
                isRetryable: retryableURLErrorCodes.contains(urlError.code)
            )
        }

        let nsError = error as NSError
        return .transportError(nsError.localizedDescription, isRetryable: false)
    }

    private static let retryableURLErrorCodes: Set<URLError.Code> = [
        .timedOut,
        .cannotFindHost,
        .cannotConnectToHost,
        .dnsLookupFailed,
        .networkConnectionLost,
        .notConnectedToInternet,
        .resourceUnavailable,
        .internationalRoamingOff,
        .callIsActive,
        .dataNotAllowed,
        .cannotLoadFromNetwork,
        .backgroundSessionWasDisconnected
    ]
}
