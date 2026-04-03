import Foundation

protocol DeviceModelProviderProtocol: Sendable {
    @MainActor
    func deviceModel() -> String
}
