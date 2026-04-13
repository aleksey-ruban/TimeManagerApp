import Foundation

extension Optional {
    func unwrap(or error: @autoclosure () -> Error) throws -> Wrapped {
        guard let value = self else {
            throw error()
        }
        return value
    }
}
