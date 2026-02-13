//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreDataKit
import Foundation

/// Provides centralized Core Data store configuration values.
public struct CoreDataStoreConfigurationProvider {
    /// The local database name used for storage.
    public let localDatabaseName: String
    /// The iCloud database name used for CloudKit storage.
    public let cloudDatabaseName: String
    /// The CloudKit container identifier used for iCloud sync.
    public let cloudContainerIdentifier: String

    /// Creates a provider with the app's standard configuration.
    public init() {
        localDatabaseName = "DataBase"
        cloudDatabaseName = "DataBaseCloud"
        cloudContainerIdentifier = AppInfo().cloudContainerId
    }

    /// Creates a Core Data store configuration for the given iCloud state.
    ///
    /// - Parameter isICloudEnabled: Indicates whether iCloud should be enabled.
    /// - Returns: A `CoreDataManager.StoreConfiguration` for the requested state.
    public func storeConfiguration(isICloudEnabled: Bool) -> CoreDataManager.StoreConfiguration {
        CoreDataManager.StoreConfiguration(
            isICloudEnabled: isICloudEnabled,
            localDatabaseName: localDatabaseName,
            cloudDatabaseName: cloudDatabaseName,
            cloudContainerIdentifier: cloudContainerIdentifier
        )
    }

    /// Returns the database name for the given iCloud state.
    ///
    /// - Parameter isICloudEnabled: Indicates whether iCloud should be enabled.
    /// - Returns: The database name for the requested state.
    public func databaseName(isICloudEnabled: Bool) -> String {
        isICloudEnabled ? cloudDatabaseName : localDatabaseName
    }
}
