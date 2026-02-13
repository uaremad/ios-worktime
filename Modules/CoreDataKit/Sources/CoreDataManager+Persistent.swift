//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// An extension providing additional functionality to the `CoreDataManager` class.
extension CoreDataManager {
    /// Encapsulates configuration needed to update the Core Data store setup.
    public struct StoreConfiguration: Sendable {
        /// Indicates whether iCloud sync should be enabled.
        public let isICloudEnabled: Bool
        /// The database name used for local storage.
        public let localDatabaseName: String
        /// The database name used for iCloud storage.
        public let cloudDatabaseName: String
        /// The CloudKit container identifier used for iCloud sync.
        public let cloudContainerIdentifier: String

        /// Creates a new store configuration.
        public init(
            isICloudEnabled: Bool,
            localDatabaseName: String,
            cloudDatabaseName: String,
            cloudContainerIdentifier: String
        ) {
            self.isICloudEnabled = isICloudEnabled
            self.localDatabaseName = localDatabaseName
            self.cloudDatabaseName = cloudDatabaseName
            self.cloudContainerIdentifier = cloudContainerIdentifier
        }
    }

    /// Applies a new store configuration and reloads the persistent container.
    ///
    /// - Parameter configuration: The configuration used to update the store.
    public func applyStoreConfiguration(_ configuration: StoreConfiguration) {
        databaseName = configuration.isICloudEnabled
            ? configuration.cloudDatabaseName
            : configuration.localDatabaseName
        if configuration.isICloudEnabled {
            iCloudSyncMode = .container(
                containerID: configuration.cloudContainerIdentifier,
                scope: .private
            )
        } else {
            iCloudSyncMode = .none
        }
        print("[COREDATA] Applying store configuration (iCloud=\(configuration.isICloudEnabled))")
        reloadPersistentContainer()
    }

    /// The managed object context associated with the main queue.
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    /// The list of persistent stores associated with the persistent container.
    var listOfPersistentStores: [NSPersistentStore] {
        persistentContainer.persistentStoreCoordinator.persistentStores
    }

    /// Initializes the Core Data stack asynchronously.
    ///
    /// - Parameter completion: A closure to be called upon completion of initialization.
    func initialize(_ completion: ((NSPersistentContainer) -> Void)? = nil) {
        print("[COREDATA] Initializing persistent container")
        container = makeContainer()
        guard let container else {
            fatalError("Container is nil. Unable to proceed.")
        }
        print("[COREDATA] Persistent container initialized")
        completion?(container)
    }

    /// Reloads the persistent container asynchronously.
    ///
    /// - Parameter completion: A closure to be called upon completion of reloading.
    func reloadPersistentContainer(_ completion: ((NSPersistentContainer) -> Void)? = nil) {
        print("[COREDATA] Reloading persistent container")
        container = makeContainer()
        guard let container else {
            fatalError("Container is nil. Unable to proceed.")
        }
        print("[COREDATA] Persistent container reloaded")
        completion?(container)
    }
}
