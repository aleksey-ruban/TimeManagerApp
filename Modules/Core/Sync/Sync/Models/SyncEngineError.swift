import Foundation

public enum SyncEngineError: Error, Sendable, Equatable {
    case alreadyRunning
    case networkUnavailable
}
