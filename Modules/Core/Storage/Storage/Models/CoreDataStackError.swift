import Foundation

public enum CoreDataStackError: LocalizedError {
    case managedObjectModelNotFound(modelName: String, bundleIdentifier: String?)
    case persistentStoreLoadFailed(underlyingError: Error)

    public var errorDescription: String? {
        switch self {
        case let .managedObjectModelNotFound(modelName, bundleIdentifier):
            "Core Data model '\(modelName)' was not found in bundle '\(bundleIdentifier ?? "unknown")'."
        case let .persistentStoreLoadFailed(underlyingError):
            "Persistent store failed to load: \(underlyingError.localizedDescription)"
        }
    }
}
