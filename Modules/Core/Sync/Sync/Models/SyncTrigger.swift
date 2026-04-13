import Foundation

public enum SyncTrigger: Sendable, Equatable {
    case manual
    case appLaunch
    case foreground
    case localChange
    case periodic
    case retry
}
