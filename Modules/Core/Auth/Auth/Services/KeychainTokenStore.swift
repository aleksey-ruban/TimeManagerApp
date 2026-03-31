import Foundation
import Security

final class KeychainTokenStore: TokenStoreProtocol, @unchecked Sendable {
    private let service: String
    private let account: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        service: String = "com.alekseyruban.TimeManagerApp.auth",
        account: String = "default"
    ) {
        self.service = service
        self.account = account
    }

    func load() throws -> StoredAuthSession? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data else {
                throw AuthError.invalidAuthResponse
            }

            return try decoder.decode(StoredAuthSession.self, from: data)
        case errSecItemNotFound:
            return nil
        default:
            throw keychainError(status)
        }
    }

    func save(_ session: StoredAuthSession) throws {
        let data = try encoder.encode(session)
        var query = baseQuery
        let attributesToUpdate = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

        if updateStatus == errSecItemNotFound {
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw keychainError(addStatus)
            }

            return
        }

        guard updateStatus == errSecSuccess else {
            throw keychainError(updateStatus)
        }
    }

    func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
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
