//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// Defines errors that can occur while migrating local and iCloud stores.
public enum ICloudSyncMigrationError: Error {
    /// Indicates the Core Data model could not be loaded.
    case missingModel
    /// Indicates the storage directory could not be created.
    case storageDirectoryUnavailable
    /// Indicates the iCloud container identifier is missing.
    case missingCloudContainerIdentifier
    /// Indicates replacing the destination store failed.
    case replaceFailed(underlyingError: Error)
}

/// Handles data synchronization between local and iCloud persistent stores.
public enum ICloudSyncMigrationService {
    /// Encapsulates all data required to perform a store migration.
    public struct MigrationRequest: Sendable {
        /// The current iCloud sync state.
        public let fromICloudEnabled: Bool
        /// The target iCloud sync state.
        public let toICloudEnabled: Bool
        /// The active managed object context to save before copying.
        public let context: NSManagedObjectContext?
        /// The Core Data model name.
        public let modelName: String
        /// The storage path where the SQLite files live.
        public let storagePath: LocalStoragePath
        /// The database name used for local storage.
        public let localDatabaseName: String
        /// The database name used for iCloud storage.
        public let cloudDatabaseName: String
        /// The CloudKit container identifier used for iCloud sync.
        public let cloudContainerIdentifier: String

        /// Creates a new migration request with required configuration.
        public init(
            fromICloudEnabled: Bool,
            toICloudEnabled: Bool,
            context: NSManagedObjectContext?,
            modelName: String,
            storagePath: LocalStoragePath,
            localDatabaseName: String,
            cloudDatabaseName: String,
            cloudContainerIdentifier: String
        ) {
            self.fromICloudEnabled = fromICloudEnabled
            self.toICloudEnabled = toICloudEnabled
            self.context = context
            self.modelName = modelName
            self.storagePath = storagePath
            self.localDatabaseName = localDatabaseName
            self.cloudDatabaseName = cloudDatabaseName
            self.cloudContainerIdentifier = cloudContainerIdentifier
        }
    }

    /// Synchronizes data from the current store to the target store.
    ///
    /// - Parameter request: The migration request containing all required configuration.
    /// - Throws: `ICloudSyncMigrationError` when migration fails.
    public static func synchronizeStores(
        request: MigrationRequest
    ) async throws(ICloudSyncMigrationError) {
        print("[COREDATA] Sync request: from=\(request.fromICloudEnabled) to=\(request.toICloudEnabled)")
        guard request.fromICloudEnabled != request.toICloudEnabled else { return }
        if request.toICloudEnabled, request.cloudContainerIdentifier.isEmpty {
            print("[COREDATA] Missing CloudKit container identifier")
            throw .missingCloudContainerIdentifier
        }
        try await saveContextIfNeeded(request.context)
        print("[COREDATA] Context saved before migration")

        let model = try loadManagedModel(modelName: request.modelName)
        print("[COREDATA] Managed object model loaded: \(request.modelName)")
        let sourceUrl = try storeUrl(
            isICloudEnabled: request.fromICloudEnabled,
            storagePath: request.storagePath,
            localDatabaseName: request.localDatabaseName,
            cloudDatabaseName: request.cloudDatabaseName
        )
        let destinationUrl = try storeUrl(
            isICloudEnabled: request.toICloudEnabled,
            storagePath: request.storagePath,
            localDatabaseName: request.localDatabaseName,
            cloudDatabaseName: request.cloudDatabaseName
        )
        print("[COREDATA] Source store URL: \(sourceUrl.path)")
        print("[COREDATA] Destination store URL: \(destinationUrl.path)")

        guard FileManager.default.fileExists(atPath: sourceUrl.path) else { return }
        print("[COREDATA] Source store exists, replacing destination store")

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try coordinator.replacePersistentStore(
                at: destinationUrl,
                destinationOptions: nil,
                withPersistentStoreFrom: sourceUrl,
                sourceOptions: nil,
                ofType: NSSQLiteStoreType
            )
            print("[COREDATA] Persistent store replacement completed")
        } catch {
            print("[COREDATA] Persistent store replacement failed: \(error)")
            throw .replaceFailed(underlyingError: error)
        }
    }

    /// Saves pending changes in the provided context.
    ///
    /// - Parameter context: The managed object context to save.
    private static func saveContextIfNeeded(
        _ context: NSManagedObjectContext?
    ) async throws(ICloudSyncMigrationError) {
        guard let context else { return }
        do {
            try await context.perform {
                if context.hasChanges {
                    print("[COREDATA] Saving context changes before migration")
                    try context.save()
                }
            }
        } catch {
            throw .replaceFailed(underlyingError: error)
        }
    }

    /// Loads the managed object model from the main bundle.
    ///
    /// - Parameter modelName: The Core Data model name.
    /// - Returns: The managed object model.
    private static func loadManagedModel(
        modelName: String
    ) throws(ICloudSyncMigrationError) -> NSManagedObjectModel {
        print("[COREDATA] Loading managed object model: \(modelName)")
        guard let modelUrl = Bundle.main.url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelUrl)
        else {
            throw .missingModel
        }
        return model
    }

    /// Resolves the store URL for the given iCloud mode.
    ///
    /// - Parameters:
    ///   - isICloudEnabled: Whether iCloud sync is enabled.
    ///   - storagePath: The storage path where the SQLite files live.
    ///   - localDatabaseName: The database name used for local storage.
    ///   - cloudDatabaseName: The database name used for iCloud storage.
    /// - Returns: The resolved SQLite store URL.
    private static func storeUrl(
        isICloudEnabled: Bool,
        storagePath: LocalStoragePath,
        localDatabaseName: String,
        cloudDatabaseName: String
    ) throws(ICloudSyncMigrationError) -> URL {
        print("[COREDATA] Resolving store URL (iCloudEnabled=\(isICloudEnabled))")
        let directoryUrl = try storeDirectoryUrl(storagePath: storagePath)
        let databaseName = isICloudEnabled ? cloudDatabaseName : localDatabaseName
        return directoryUrl.appendingPathComponent("\(databaseName).sqlite")
    }

    /// Resolves and creates the store directory if needed.
    ///
    /// - Parameter storagePath: The storage path where the SQLite files live.
    /// - Returns: The directory URL used for Core Data stores.
    private static func storeDirectoryUrl(
        storagePath: LocalStoragePath
    ) throws(ICloudSyncMigrationError) -> URL {
        print("[COREDATA] Resolving store directory URL")
        guard let baseUrl = storagePath.url else {
            throw .storageDirectoryUnavailable
        }
        do {
            try FileManager.default.createDirectory(at: baseUrl, withIntermediateDirectories: true)
        } catch {
            throw .storageDirectoryUnavailable
        }
        return baseUrl
    }
}
