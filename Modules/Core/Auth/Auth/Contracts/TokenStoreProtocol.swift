import Foundation

protocol TokenStoreProtocol: Sendable {
    func load() throws -> StoredAuthSession?
    func save(_ session: StoredAuthSession) throws
    func clear() throws
}
