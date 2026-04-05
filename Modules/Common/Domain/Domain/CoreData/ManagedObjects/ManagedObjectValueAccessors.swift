import Foundation

public extension CategoryMO {
    var remoteIDValue: Int64? { remoteID?.int64Value }
    var lastModifiedVersionValue: Int64? { lastModifiedVersion?.int64Value }
    var code: CategoryCode? {
        get { codeRawValue.flatMap(CategoryCode.init(rawValue:)) }
        set { codeRawValue = newValue?.rawValue }
    }
}

public extension ActivityMO {
    var remoteIDValue: Int64? { remoteID?.int64Value }
    var lastModifiedVersionValue: Int64? { lastModifiedVersion?.int64Value }
    var color: ActivityColor {
        get { ActivityColor(rawValue: colorRawValue) ?? .gray }
        set { colorRawValue = newValue.rawValue }
    }
}

public extension ActivityVariationMO {
    var remoteIDValue: Int64? { remoteID?.int64Value }
}

public extension ActivityRecordMO {
    var remoteIDValue: Int64? { remoteID?.int64Value }
    var lastModifiedVersionValue: Int64? { lastModifiedVersion?.int64Value }
}

public extension ChronometryMO {
    var remoteIDValue: Int64? { remoteID?.int64Value }
    var lastModifiedVersionValue: Int64? { lastModifiedVersion?.int64Value }
}

public extension CategorySnapshotMO {
    var remoteIDValue: Int64? { remoteID?.int64Value }
    var globalCategoryIDValue: Int64? { globalCategoryID?.int64Value }
    var code: CategoryCode? {
        get { codeRawValue.flatMap(CategoryCode.init(rawValue:)) }
        set { codeRawValue = newValue?.rawValue }
    }
}

public extension ActivitySnapshotMO {
    var remoteIDValue: Int64? { remoteID?.int64Value }
    var globalActivityIDValue: Int64? { globalActivityID?.int64Value }
    var color: ActivityColor {
        get { ActivityColor(rawValue: colorRawValue) ?? .gray }
        set { colorRawValue = newValue.rawValue }
    }
}

public extension ActivityVariationSnapshotMO {
    var remoteIDValue: Int64? { remoteID?.int64Value }
    var globalActivityVariationIDValue: Int64? { globalActivityVariationID?.int64Value }
}

public extension ActivityRecordSnapshotMO {
    var remoteIDValue: Int64? { remoteID?.int64Value }
    var globalActivityRecordIDValue: Int64? { globalActivityRecordID?.int64Value }
}
