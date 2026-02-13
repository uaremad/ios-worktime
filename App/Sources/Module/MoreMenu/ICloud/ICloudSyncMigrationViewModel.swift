//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import CoreDataKit
import Foundation
import Observation

/// Manages iCloud synchronization migrations for Core Data stores.
@MainActor
@Observable
final class ICloudSyncMigrationViewModel {
    /// Holds the migration configuration for Core Data stores.
    private let configuration: MigrationConfiguration

    /// Creates a new migration view model with default configuration.
    init() {
        configuration = MigrationConfiguration()
    }

    /// Handles iCloud sync changes and synchronizes stores when needed.
    ///
    /// - Parameters:
    ///   - oldSelection: The previous iCloud sync setting.
    ///   - newSelection: The updated iCloud sync setting.
    ///   - context: The managed object context to save before copying.
    /// - Returns: `true` when migration completed successfully.
    func synchronizeStores(
        oldSelection: Bool,
        newSelection: Bool,
        context: NSManagedObjectContext
    ) async -> Bool {
        let currentConfiguration = configuration
        do {
            let request = ICloudSyncMigrationService.MigrationRequest(
                fromICloudEnabled: oldSelection,
                toICloudEnabled: newSelection,
                context: context,
                modelName: currentConfiguration.modelName,
                storagePath: currentConfiguration.storagePath,
                localDatabaseName: currentConfiguration.localDatabaseName,
                cloudDatabaseName: currentConfiguration.cloudDatabaseName,
                cloudContainerIdentifier: currentConfiguration.cloudContainerIdentifier
            )
            try await ICloudSyncMigrationService.synchronizeStores(request: request)
            return true
        } catch {
            return false
        }
    }
}

private extension ICloudSyncMigrationViewModel {
    /// Provides configuration values for store migrations.
    struct MigrationConfiguration: Sendable {
        /// The Core Data model name.
        let modelName: String
        /// The local storage path for database files.
        let storagePath: LocalStoragePath
        /// The local database name.
        let localDatabaseName: String
        /// The iCloud database name.
        let cloudDatabaseName: String
        /// The CloudKit container identifier.
        let cloudContainerIdentifier: String

        /// Creates a configuration using current app values.
        init() {
            let provider = CoreDataStoreConfigurationProvider()
            modelName = "Worktime"
            storagePath = .libraryDirectory(appending: "Private Documents")
            localDatabaseName = provider.localDatabaseName
            cloudDatabaseName = provider.cloudDatabaseName
            cloudContainerIdentifier = provider.cloudContainerIdentifier
        }
    }
}
