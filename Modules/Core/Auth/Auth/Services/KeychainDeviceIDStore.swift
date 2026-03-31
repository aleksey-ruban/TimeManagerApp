import Foundation
import Security

final class KeychainDeviceIDStore: DeviceIDStoreProtocol, @unchecked Sendable {
    private let service: String
    private let account: String

    init(
        service: String = "com.alekseyruban.TimeManagerApp.auth.device",
        account: String = "device-id"
    ) {
        self.service = service
        self.account = account
    }

    func loadOrCreateDeviceID() throws -> String {
        if let existingDeviceID = try loadDeviceID() {
            return existingDeviceID
        }

        let deviceID = UUID().uuidString.lowercased()
        try save(deviceID)
        return deviceID
    }

    private func loadDeviceID() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard
                let data = item as? Data,
                let deviceID = String(data: data, encoding: .utf8)
            else {
                throw AuthError.invalidAuthResponse
            }

            return deviceID
        case errSecItemNotFound:
            return nil
        default:
            throw keychainError(status)
        }
    }

    private func save(_ deviceID: String) throws {
        guard let data = deviceID.data(using: .utf8) else {
            throw AuthError.invalidAuthResponse
        }

        var query = baseQuery
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw keychainError(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    private func keychainError(_ status: OSStatus) -> NSError {
        NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
}
