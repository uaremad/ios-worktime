//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

extension CoreDataManager {
    /// A method for creating and configuring the persistent container for Core Data operations.
    ///
    /// - Returns: The configured persistent container.
    func makeContainer() -> NSPersistentContainer {
        // Create the container using the managed object model.
        print("[COREDATA] Creating persistent container with model: \(nameModel)")
        let container = NSPersistentContainer(name: nameModel, managedObjectModel: managedModel)

        // Ensure that at least one persistent store type is specified.
        guard !persistentStores.isEmpty else {
            fatalError("Storage type not specified")
        }

        /// Builds persistent store descriptions for the configured store types.
        ///
        /// - Returns: The configured persistent store descriptions.
        func makeDescriptions() -> [NSPersistentStoreDescription] {
            print("[COREDATA] Building store descriptions")
            // Configure persistent store descriptions for each persistent store type.
            return persistentStores.map { store in
                let storeDescription = NSPersistentStoreDescription()
                storeDescription.type = store.stringValue
                storeDescription.shouldMigrateStoreAutomatically = true
                storeDescription.shouldInferMappingModelAutomatically = true

                // Set user transformations for the store description.
                if let storeTransformer {
                    storeTransformer.transform(store, storeDescription)
                }

                // If SQLite store type is specified, configure SQLite URL and CloudKit options.
                if store == .sqLite {
                    guard let baseUrl = databaseStorage.url else {
                        fatalError("CoreDataManager can't create storage directory url")
                    }
                    do {
                        try FileManager.default.createDirectory(at: baseUrl, withIntermediateDirectories: true)
                        print("[COREDATA] Ensured storage directory: \(baseUrl.path)")
                    } catch {
                        print("[COREDATA] Failed to create storage directory: \(error)")
                    }
                    let sqliteUrl = baseUrl.appendingPathComponent("\(databaseName).sqlite")
                    if sqliteUrl.path.isEmpty {
                        fatalError("CoreDataManager can't create sqlite url")
                    }
                    storeDescription.url = sqliteUrl
                    print("[COREDATA] Using SQLite store URL: \(sqliteUrl.path)")

                    // Explicitly keep local-only storage without CloudKit.
                    storeDescription.cloudKitContainerOptions = nil
                    print("[COREDATA] Using local SQLite store without CloudKit")

                    // Enable persistent history tracking for local peer delta synchronization.
                    storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                    storeDescription.setOption(
                        true as NSNumber,
                        forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
                    )
                }

                return storeDescription
            }
        }

        // Load persistent stores with the configured descriptions.
        container.persistentStoreDescriptions = makeDescriptions()
        container.loadPersistentStores { _, error in
            if let error {
                print("[COREDATA] Failed to load persistent stores: \(error)")
            } else {
                print("[COREDATA] Persistent stores loaded successfully")
            }
            guard let error else { return }
            fatalError("Failed to load persistent stores: \(error)")
        }

        // Configure view context merge policy.
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        return container
    }
}
