import Foundation

public protocol AuthInterceptorProtocol: NetworkClientProtocol {
    func setNextClient(_ client: NetworkClientProtocol)
}
