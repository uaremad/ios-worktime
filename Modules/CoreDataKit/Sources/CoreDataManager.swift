//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// A class responsible for managing Core Data operations.
open class CoreDataManager: CoreDataManagerProtocol {
    // MARK: - Internal Shared

    /// The shared instance of `CoreDataManager`.
    public static var shared: CoreDataManager?

    // MARK: - Publics Properties

    /// The mode of synchronization with iCloud.
    public var iCloudSyncMode: CloudSyncMode = .none

    /// The persistent container for Core Data. This is lazily initialized.
    /// - Returns: The persistent container for Core Data.
    public var persistentContainer: NSPersistentContainer {
        guard let container else {
            fatalError("PersistentContainer must be set up using `initialize()` before it can be used.")
        }

        return container
    }

    // MARK: - Private Properties

    /// An array of persistent store types.
    var persistentStores: [PersistentStoreType] = [.sqLite]

    /// A transformer for the persistent store.
    var storeTransformer: StoreTransformer?

    /// The managed object model.
    var managedModel: NSManagedObjectModel

    /// The name of the managed object model.
    var nameModel: String

    /// The name of the database.
    var databaseName: String

    /// The storage path of the SQLITE
    var databaseStorage: LocalStoragePath

    /// The persistent container for Core Data.
    var container: NSPersistentContainer?

    /// The managed object context associated with the background queue.
    lazy var backgroundContext: NSManagedObjectContext = persistentContainer.newBackgroundContext()

    // MARK: - Initialize

    /// Initializes the `CoreDataManager` using the provided bundle.
    ///
    /// - Parameters:
    ///   - bundle: The bundle containing the Core Data model.
    ///   - model: The name of the Core Data model.
    ///   - database: The name of the database to be used.
    public required init(
        bundle: Bundle,
        nameModel model: String,
        databaseName database: String? = nil,
        databaseStorage storage: LocalStoragePath = .applicationSupportDirectory(),
        iCloudSyncMode syncMode: CloudSyncMode = .none
    ) {
        guard let managedModel = Self.loadModel(bundle: bundle, use: nil, modelName: model) else {
            fatalError("Failed to load NSManagedObjectModel from bundle path: \(bundle.bundlePath)")
        }

        self.managedModel = managedModel
        nameModel = model
        databaseName = database ?? model
        databaseStorage = storage
        iCloudSyncMode = syncMode
        Self.shared = self
        container = makeContainer()
    }

    /// Initializes the `CoreDataManager` using the provided URL.
    ///
    /// - Parameters:
    ///   - url: The file URL of the Core Data model.
    ///   - model: The name of the Core Data model.
    ///   - database: The name of the database to be used.
    public required init(
        url: URL,
        nameModel model: String,
        databaseName database: String? = nil,
        databaseStorage storage: LocalStoragePath = .applicationSupportDirectory(),
        iCloudSyncMode syncMode: CloudSyncMode = .none
    ) {
        guard let managedModel = Self.loadModel(bundle: nil, use: url, modelName: model) else {
            fatalError("Failed to load NSManagedObjectModel from url:  \(url.absoluteString)")
        }

        self.managedModel = managedModel
        nameModel = model
        databaseName = database ?? model
        databaseStorage = storage
        iCloudSyncMode = syncMode
        Self.shared = self
        container = makeContainer()
    }
}
