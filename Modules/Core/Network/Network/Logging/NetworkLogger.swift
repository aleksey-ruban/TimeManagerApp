import Foundation
import OSLog

public enum NetworkLoggingMode: String, Sendable, Equatable {
    case disabled
    case enabled
    case debugOnly
}

public struct NetworkLoggingConfiguration: Sendable, Equatable {
    public let mode: NetworkLoggingMode

    public init(mode: NetworkLoggingMode) {
        self.mode = mode
    }

    public static let disabled = NetworkLoggingConfiguration(mode: .disabled)
    public static let enabled = NetworkLoggingConfiguration(mode: .enabled)
    public static let debugOnly = NetworkLoggingConfiguration(mode: .debugOnly)

    var isEnabled: Bool {
        switch mode {
        case .disabled:
            return false
        case .enabled:
            return true
        case .debugOnly:
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
    }
}

protocol NetworkLogging: Sendable {
    func logRequest(_ request: URLRequest)
}

protocol NetworkLogWriting: Sendable {
    func write(_ message: String)
}

struct NetworkLogger: NetworkLogging {
    private let configuration: NetworkLoggingConfiguration
    private let writer: NetworkLogWriting

    init(
        configuration: NetworkLoggingConfiguration,
        writer: NetworkLogWriting = OSLogNetworkLogWriter()
    ) {
        self.configuration = configuration
        self.writer = writer
    }

    func logRequest(_ request: URLRequest) {
        guard configuration.isEnabled else {
            return
        }

        writer.write(format(request))
    }

    private func format(_ request: URLRequest) -> String {
        let url = request.url
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let path = url?.path.isEmpty == false ? url?.path ?? "-" : "/"
        let method = request.httpMethod ?? "UNKNOWN"
        let parameters = formatQueryItems(components?.queryItems ?? [])
        let headers = formatHeaders(request.allHTTPHeaderFields ?? [:])
        let cookies = formatCookies(request.allHTTPHeaderFields?["Cookie"])
        let body = formatBody(request.httpBody)

        return """
        [Network] \(method) \(path)
        URL: \(url?.absoluteString ?? "-")
        Parameters: \(parameters)
        Headers: \(headers)
        Cookies: \(cookies)
        Body: \(body)
        """
    }

    private func formatQueryItems(_ items: [URLQueryItem]) -> String {
        guard items.isEmpty == false else {
            return "-"
        }

        return items
            .map { "\($0.name)=\($0.value ?? "")" }
            .joined(separator: ", ")
    }

    private func formatHeaders(_ headers: [String: String]) -> String {
        guard headers.isEmpty == false else {
            return "-"
        }

        return headers
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")
    }

    private func formatCookies(_ cookieHeader: String?) -> String {
        guard let cookieHeader, cookieHeader.isEmpty == false else {
            return "-"
        }

        return cookieHeader
            .split(separator: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: ", ")
    }

    private func formatBody(_ body: Data?) -> String {
        guard let body, body.isEmpty == false else {
            return "-"
        }

        if let string = String(data: body, encoding: .utf8) {
            return string
        }

        return "<\(body.count) bytes>"
    }
}

private struct OSLogNetworkLogWriter: NetworkLogWriting {
    private let logger = Logger(
        subsystem: "com.alekseyruban.TimeManagerApp.CoreNetwork",
        category: "network"
    )

    func write(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }
}
