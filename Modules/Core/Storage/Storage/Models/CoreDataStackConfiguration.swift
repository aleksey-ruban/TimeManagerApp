@preconcurrency import CoreData
import Foundation

public struct CoreDataStackConfiguration {
    public let modelName: String
    public let bundle: Bundle
    public let managedObjectModel: NSManagedObjectModel?
    public let storeType: String
    public let storeURL: URL?
    public let shouldAddStoreAsynchronously: Bool
    public let shouldMigrateStoreAutomatically: Bool
    public let shouldInferMappingModelAutomatically: Bool
    public let viewContextMergePolicy: NSMergePolicy
    public let backgroundContextMergePolicy: NSMergePolicy

    public init(
        modelName: String,
        bundle: Bundle = .main,
        managedObjectModel: NSManagedObjectModel? = nil,
        storeType: String = NSSQLiteStoreType,
        storeURL: URL? = nil,
        shouldAddStoreAsynchronously: Bool = false,
        shouldMigrateStoreAutomatically: Bool = true,
        shouldInferMappingModelAutomatically: Bool = true,
        viewContextMergePolicy: NSMergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType),
        backgroundContextMergePolicy: NSMergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
    ) {
        self.modelName = modelName
        self.bundle = bundle
        self.managedObjectModel = managedObjectModel
        self.storeType = storeType
        self.storeURL = storeURL
        self.shouldAddStoreAsynchronously = shouldAddStoreAsynchronously
        self.shouldMigrateStoreAutomatically = shouldMigrateStoreAutomatically
        self.shouldInferMappingModelAutomatically = shouldInferMappingModelAutomatically
        self.viewContextMergePolicy = viewContextMergePolicy
        self.backgroundContextMergePolicy = backgroundContextMergePolicy
    }

    public static func inMemory(
        modelName: String,
        managedObjectModel: NSManagedObjectModel? = nil,
        bundle: Bundle = .main,
        viewContextMergePolicy: NSMergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType),
        backgroundContextMergePolicy: NSMergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
    ) -> Self {
        Self(
            modelName: modelName,
            bundle: bundle,
            managedObjectModel: managedObjectModel,
            storeType: NSInMemoryStoreType,
            storeURL: nil,
            shouldAddStoreAsynchronously: false,
            shouldMigrateStoreAutomatically: false,
            shouldInferMappingModelAutomatically: false,
            viewContextMergePolicy: viewContextMergePolicy,
            backgroundContextMergePolicy: backgroundContextMergePolicy
        )
    }
}
