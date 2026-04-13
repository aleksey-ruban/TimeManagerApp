import Foundation

class NetworkSessionFactory {
    static func makeDefault(cookieStorage: HTTPCookieStorage? = .shared) -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = cookieStorage
        configuration.httpShouldSetCookies = true
        configuration.httpCookieAcceptPolicy = .always
        return URLSession(configuration: configuration)
    }
}
