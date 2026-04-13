import Foundation

struct CategoryPushAcknowledgement: Sendable {
    let localID: UUID
    let remoteID: Int64?
    let lastModifiedVersion: Int64?
}

struct ActivityPushAcknowledgement: Sendable {
    let localID: UUID
    let remoteID: Int64?
    let lastModifiedVersion: Int64?
}

struct ActivityRecordPushAcknowledgement: Sendable {
    let localID: UUID
    let remoteID: Int64?
    let lastModifiedVersion: Int64?
}

struct ChronometryPushAcknowledgement: Sendable {
    let localID: UUID
    let remoteID: Int64?
    let lastModifiedVersion: Int64?
}
