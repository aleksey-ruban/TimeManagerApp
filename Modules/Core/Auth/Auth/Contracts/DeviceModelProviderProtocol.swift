import Foundation

protocol DeviceModelProviderProtocol: Sendable {
    func deviceModel() -> String
}
