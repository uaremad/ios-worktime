//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

// Protocol
/// A protocol defining the requirements for managing persistence and synchronization in Core Data.
protocol CoreDataManagerProtocol {
    /// The type representing the cloud synchronization mode.
    associatedtype CloudSyncMode

    /// The type representing the persistent store.
    associatedtype PersistentStoreType

    /// Initializes the persistent store using the provided bundle.
    ///
    /// - Parameters:
    ///   - bundle: The bundle containing the Core Data model.
    ///   - model: The name of the Core Data model.
    ///   - database: The name of the database to be used.
    ///   - databaseStorage: The storage path for the local database.
    ///   - syncMode: The iCloud synchronization mode.
    init(
        bundle: Bundle,
        nameModel model: String,
        databaseName database: String?,
        databaseStorage: LocalStoragePath,
        iCloudSyncMode syncMode: CloudSyncMode
    )

    /// Initializes the persistent store using the provided URL.
    ///
    /// - Parameters:
    ///   - modelURL: The file URL of the Core Data model.
    ///   - model: The name of the Core Data model.
    ///   - database: The name of the database to be used.
    ///   - databaseStorage: The storage path for the local database.
    ///   - syncMode: The iCloud synchronization mode.
    init(
        url modelURL: URL,
        nameModel model: String,
        databaseName database: String?,
        databaseStorage: LocalStoragePath,
        iCloudSyncMode syncMode: CloudSyncMode
    )

    /// The mode of synchronization with iCloud.
    var iCloudSyncMode: CloudSyncMode { get set }

    /// An array of persistent stores.
    var persistentStores: [PersistentStoreType] { get set }

    /// Initializes the Core Data stack asynchronously.
    ///
    /// - Parameter completion: A closure to be called upon completion of initialization.
    func initialize(_ completion: ((NSPersistentContainer) -> Void)?)

    /// Reloads the persistent container asynchronously.
    ///
    /// - Parameter completion: A closure to be called upon completion of reloading.
    func reloadPersistentContainer(_ completion: ((NSPersistentContainer) -> Void)?)

    /// The managed object context associated with the main queue.
    var viewContext: NSManagedObjectContext { get }

    /// The managed object context associated with the background queue.
    var backgroundContext: NSManagedObjectContext { get }
}
