import Domain
import Foundation

public enum SyncOperationDTO: String, Codable, Sendable, Hashable {
    case create = "CREATE"
    case update = "UPDATE"
    case delete = "DELETE"
}

public enum SyncObjectTypeDTO: String, Codable, Sendable, Hashable {
    case category = "CATEGORY"
    case activity = "ACTIVITY"
    case activityRecord = "ACTIVITY_RECORD"
    case chronometrySnapshot = "CHRONOMETRY_SNAPSHOT"
}

public struct RemoteCategoryDTO: Codable, Sendable, Hashable {
    public let id: Int64
    public let lastModifiedVersion: Int64
    public let name: String
    public let code: CategoryCode?
    public let deleted: Bool
}

public struct RemoteVariationDTO: Codable, Sendable, Hashable {
    public let id: Int64?
    public let position: Int
    public let value: String
    public let deleted: Bool
}

public struct RemoteActivityDTO: Codable, Sendable, Hashable {
    public let id: Int64
    public let lastModifiedVersion: Int64
    public let name: String
    public let categoryId: Int64?
    public let icon: String
    public let iconColor: String
    public let variations: [RemoteVariationDTO]
    public let deleted: Bool
}

public struct RemoteActivityRecordDTO: Codable, Sendable, Hashable {
    public let id: Int64
    public let lastModifiedVersion: Int64
    public let activityId: Int64
    public let variationId: Int64?
    public let startedAt: Date
    public let endedAt: Date?
    public let timeZone: String
    public let deleted: Bool
}

public struct RemoteCategorySnapshotDTO: Codable, Sendable, Hashable {
    public let id: Int64?
    public let baseName: String
    public let code: CategoryCode?
    public let globalCategoryId: Int64?
}

public struct RemoteActivitySnapshotDTO: Codable, Sendable, Hashable {
    public let id: Int64?
    public let globalActivityId: Int64?
    public let name: String
    public let categorySnapshotId: Int64?
    public let icon: String
    public let iconColor: String
}

public struct RemoteActivityVariationSnapshotDTO: Codable, Sendable, Hashable {
    public let id: Int64?
    public let globalActivityVariationId: Int64?
    public let value: String
    public let activitySnapshotId: Int64?
}

public struct RemoteActivityRecordSnapshotDTO: Codable, Sendable, Hashable {
    public let id: Int64?
    public let globalActivityRecordId: Int64?
    public let activitySnapshotId: Int64?
    public let variationSnapshotId: Int64?
    public let startedAt: Date
    public let endedAt: Date?
    public let timeZone: String
}

public struct RemoteChronometryDTO: Codable, Sendable, Hashable {
    public let id: Int64
    public let startDate: String
    public let endDate: String
    public let timeZone: String
    public let lastModifiedVersion: Int64
    public let finished: Bool
    public let deleted: Bool
    public let categorySnapshotList: [RemoteCategorySnapshotDTO]
    public let activitySnapshotList: [RemoteActivitySnapshotDTO]
    public let activityVariationSnapshotList: [RemoteActivityVariationSnapshotDTO]
    public let activityRecordSnapshotList: [RemoteActivityRecordSnapshotDTO]

    public init(
        id: Int64,
        startDate: String,
        endDate: String,
        timeZone: String,
        lastModifiedVersion: Int64,
        finished: Bool,
        deleted: Bool,
        categorySnapshotList: [RemoteCategorySnapshotDTO],
        activitySnapshotList: [RemoteActivitySnapshotDTO],
        activityVariationSnapshotList: [RemoteActivityVariationSnapshotDTO],
        activityRecordSnapshotList: [RemoteActivityRecordSnapshotDTO]
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.timeZone = timeZone
        self.lastModifiedVersion = lastModifiedVersion
        self.finished = finished
        self.deleted = deleted
        self.categorySnapshotList = categorySnapshotList
        self.activitySnapshotList = activitySnapshotList
        self.activityVariationSnapshotList = activityVariationSnapshotList
        self.activityRecordSnapshotList = activityRecordSnapshotList
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case startDate
        case endDate
        case timeZone
        case lastModifiedVersion
        case finished
        case deleted
        case categorySnapshotList
        case activitySnapshotList
        case activityVariationSnapshotList
        case activityRecordSnapshotList
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.startDate = try container.decode(String.self, forKey: .startDate)
        self.endDate = try container.decode(String.self, forKey: .endDate)
        self.timeZone = try container.decode(String.self, forKey: .timeZone)
        self.lastModifiedVersion = try container.decode(Int64.self, forKey: .lastModifiedVersion)
        self.finished = try container.decodeIfPresent(Bool.self, forKey: .finished) ?? false
        self.deleted = try container.decode(Bool.self, forKey: .deleted)
        self.categorySnapshotList = try container.decodeIfPresent([RemoteCategorySnapshotDTO].self, forKey: .categorySnapshotList) ?? []
        self.activitySnapshotList = try container.decodeIfPresent([RemoteActivitySnapshotDTO].self, forKey: .activitySnapshotList) ?? []
        self.activityVariationSnapshotList = try container.decodeIfPresent([RemoteActivityVariationSnapshotDTO].self, forKey: .activityVariationSnapshotList) ?? []
        self.activityRecordSnapshotList = try container.decodeIfPresent([RemoteActivityRecordSnapshotDTO].self, forKey: .activityRecordSnapshotList) ?? []
    }
}

public struct SyncPullRequestDTO: Encodable, Sendable {
    public let clientSnapshotVersion: SnapshotVersion
    public let batchSize: Int?
    public let cursor: String?
}

enum SyncPullPayloadDTO: Sendable, Hashable {
    case category(RemoteCategoryDTO)
    case activity(RemoteActivityDTO)
    case activityRecord(RemoteActivityRecordDTO)
    case chronometry(RemoteChronometryDTO)
}

private struct SyncPullEnvelopeDTO: Decodable, Sendable {
    let message: String?
    let data: SyncPullDataDTO
}

private struct SyncPullDataDTO: Decodable, Sendable {
    let objects: [SyncPullObjectDTO]
    let nextCursor: String?
    let hasMore: Bool
}

private struct SyncPullObjectDTO: Decodable, Sendable {
    let type: SyncObjectTypeDTO
    let payload: SyncPullPayloadDTO

    private enum CodingKeys: String, CodingKey {
        case type
        case payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(SyncObjectTypeDTO.self, forKey: .type)

        switch type {
        case .category:
            payload = .category(try container.decode(RemoteCategoryDTO.self, forKey: .payload))
        case .activity:
            payload = .activity(try container.decode(RemoteActivityDTO.self, forKey: .payload))
        case .activityRecord:
            payload = .activityRecord(try container.decode(RemoteActivityRecordDTO.self, forKey: .payload))
        case .chronometrySnapshot:
            payload = .chronometry(try container.decode(RemoteChronometryDTO.self, forKey: .payload))
        }
    }
}

public struct SyncPullBatchResponseDTO: Decodable, Sendable {
    public let nextCursor: String?
    public let hasMore: Bool
    public let categories: [RemoteCategoryDTO]
    public let activities: [RemoteActivityDTO]
    public let activityRecords: [RemoteActivityRecordDTO]
    public let chronometries: [RemoteChronometryDTO]
    public let maxSnapshotVersion: SnapshotVersion

    public init(from decoder: Decoder) throws {
        let envelope = try SyncPullEnvelopeDTO(from: decoder)

        var categories: [RemoteCategoryDTO] = []
        var activities: [RemoteActivityDTO] = []
        var activityRecords: [RemoteActivityRecordDTO] = []
        var chronometries: [RemoteChronometryDTO] = []

        for object in envelope.data.objects {
            switch object.payload {
            case let .category(dto):
                categories.append(dto)
            case let .activity(dto):
                activities.append(dto)
            case let .activityRecord(dto):
                activityRecords.append(dto)
            case let .chronometry(dto):
                chronometries.append(dto)
            }
        }

        self.nextCursor = envelope.data.nextCursor
        self.hasMore = envelope.data.hasMore
        self.categories = categories
        self.activities = activities
        self.activityRecords = activityRecords
        self.chronometries = chronometries
        self.maxSnapshotVersion = [
            categories.map(\.lastModifiedVersion).max().map(SnapshotVersion.init),
            activities.map(\.lastModifiedVersion).max().map(SnapshotVersion.init),
            activityRecords.map(\.lastModifiedVersion).max().map(SnapshotVersion.init),
            chronometries.map(\.lastModifiedVersion).max().map(SnapshotVersion.init),
        ]
        .compactMap { $0 }
        .max() ?? .zero
    }
}

public struct SyncPushRequestDTO: Encodable, Sendable {
    public let objects: [SyncPushRequestObjectDTO]
}

public struct SyncPushRequestObjectDTO: Encodable, Sendable {
    public let localId: UUID
    public let operation: SyncOperationDTO
    public let objectType: SyncObjectTypeDTO
    public let payload: AnyEncodable
}

public struct SyncPushResultDTO: Decodable, Sendable, Hashable {
    public let objectType: SyncObjectTypeDTO
    public let operation: SyncOperationDTO
    public let localId: UUID
    public let serverId: Int64?
    public let lastModifiedVersion: Int64?
    public let status: String?
    public let errorCode: String?
    public let errorMessage: String?

    public init(
        objectType: SyncObjectTypeDTO,
        operation: SyncOperationDTO,
        localId: UUID,
        serverId: Int64?,
        lastModifiedVersion: Int64?,
        status: String?,
        errorCode: String? = nil,
        errorMessage: String? = nil
    ) {
        self.objectType = objectType
        self.operation = operation
        self.localId = localId
        self.serverId = serverId
        self.lastModifiedVersion = lastModifiedVersion
        self.status = status
        self.errorCode = errorCode
        self.errorMessage = errorMessage
    }
}

private struct SyncPushEnvelopeDTO: Decodable, Sendable {
    let message: String?
    let data: SyncPushDataDTO
}

private struct SyncPushDataDTO: Decodable, Sendable {
    let results: [SyncPushResultDTO]
}

public struct SyncPushResponseDTO: Decodable, Sendable {
    public let results: [SyncPushResultDTO]

    public init(from decoder: Decoder) throws {
        let envelope = try SyncPushEnvelopeDTO(from: decoder)
        self.results = envelope.data.results
    }
}

public struct CreateCategoryPayloadDTO: Encodable, Sendable {
    public let baseName: String
    public let deleted: Bool
}

public struct UpdateCategoryPayloadDTO: Encodable, Sendable {
    public let id: Int64
    public let baseName: String
    public let lastModifiedVersion: Int64
    public let deleted: Bool
}

public struct CreateActivityVariationPayloadDTO: Encodable, Sendable {
    public let position: Int
    public let value: String
    public let deleted: Bool
}

public struct UpdateActivityVariationPayloadDTO: Encodable, Sendable {
    public let id: Int64?
    public let position: Int
    public let value: String
    public let deleted: Bool
}

public struct CreateActivityPayloadDTO: Encodable, Sendable {
    public let name: String
    public let icon: String
    public let iconColor: String
    public let categoryId: Int64?
    public let variations: [CreateActivityVariationPayloadDTO]
    public let deleted: Bool
}

public struct UpdateActivityPayloadDTO: Encodable, Sendable {
    public let id: Int64
    public let lastModifiedVersion: Int64
    public let name: String
    public let icon: String
    public let iconColor: String
    public let categoryId: Int64?
    public let variations: [UpdateActivityVariationPayloadDTO]
    public let deleted: Bool
}

public struct CreateActivityRecordPayloadDTO: Encodable, Sendable {
    public let activityId: Int64
    public let variationId: Int64?
    public let startedAt: Date
    public let endedAt: Date?
    public let timeZone: String
    public let deleted: Bool
}

public struct UpdateActivityRecordPayloadDTO: Encodable, Sendable {
    public let id: Int64
    public let variationId: Int64?
    public let startedAt: Date?
    public let endedAt: Date?
    public let timeZone: String
    public let deleted: Bool
    public let lastModifiedVersion: Int64
}

public struct CreateChronometryPayloadDTO: Encodable, Sendable {
    public let createTime: Date
    public let timeZone: String
    public let deleted: Bool
}

public struct FinishChronometryPayloadDTO: Encodable, Sendable {
    public let id: Int64
    public let finishTime: Date
    public let local: String
    public let timeZone: String
    public let snapshotVersion: SnapshotVersion
    public let deleted: Bool
}

public struct AnyEncodable: Encodable, Sendable {
    private let encodeImpl: @Sendable (Encoder) throws -> Void

    public init<Value: Encodable & Sendable>(_ value: Value) {
        self.encodeImpl = { encoder in
            try value.encode(to: encoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        try encodeImpl(encoder)
    }
}
