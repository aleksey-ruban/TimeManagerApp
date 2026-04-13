import Foundation

protocol DeviceIDStoreProtocol: Sendable {
    func loadOrCreateDeviceID() throws -> String
}
