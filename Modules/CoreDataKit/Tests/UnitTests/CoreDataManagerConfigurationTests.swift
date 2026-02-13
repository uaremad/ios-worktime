//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import XCTest
@testable import CoreDataKit

/// Tests Core Data manager configuration behaviors.
final class CoreDataManagerConfigurationTests: XCTestCase {
    /// Provides a unique file URL for a temporary Core Data model.
    private var modelUrl: URL?

    /// Prepares a temporary model file before each test.
    override func setUp() {
        super.setUp()
        modelUrl = createTemporaryModelUrl()
    }

    /// Cleans up the temporary model file after each test.
    override func tearDown() {
        if let modelUrl {
            try? FileManager.default.removeItem(at: modelUrl.deletingLastPathComponent())
        }
        modelUrl = nil
        super.tearDown()
    }

    /// Verifies LocalStoragePath resolves a valid URL for supported directories.
    func test_localStoragePath_resolvesUrls() {
        let libraryUrl = LocalStoragePath.libraryDirectory(appending: "UnitTests").url
        let supportUrl = LocalStoragePath.applicationSupportDirectory(appending: "UnitTests").url

        XCTAssertNotNil(libraryUrl)
        XCTAssertNotNil(supportUrl)
    }

    /// Verifies applying a store configuration updates database name and sync mode.
    func test_applyStoreConfiguration_updatesDatabaseAndMode() {
        guard let modelUrl else {
            XCTFail("Missing temporary model URL")
            return
        }

        let storagePath = LocalStoragePath.applicationSupportDirectory(appending: "CoreDataKitTests/\(UUID().uuidString)")
        let manager = CoreDataManager(
            url: modelUrl,
            nameModel: "TestModel",
            databaseName: "LocalStore",
            databaseStorage: storagePath,
            iCloudSyncMode: .none
        )

        let cloudConfiguration = CoreDataManager.StoreConfiguration(
            isICloudEnabled: true,
            localDatabaseName: "LocalStore",
            cloudDatabaseName: "CloudStore",
            cloudContainerIdentifier: "iCloud.test.container"
        )

        manager.applyStoreConfiguration(cloudConfiguration)

        XCTAssertEqual(manager.databaseName, "CloudStore")
        if case let .container(containerId, scope) = manager.iCloudSyncMode {
            XCTAssertEqual(containerId, "iCloud.test.container")
            XCTAssertEqual(scope, .private)
        } else {
            XCTFail("Expected CloudKit sync mode to be enabled")
        }

        let localConfiguration = CoreDataManager.StoreConfiguration(
            isICloudEnabled: false,
            localDatabaseName: "LocalStore",
            cloudDatabaseName: "CloudStore",
            cloudContainerIdentifier: "iCloud.test.container"
        )

        manager.applyStoreConfiguration(localConfiguration)

        XCTAssertEqual(manager.databaseName, "LocalStore")
        XCTAssertEqual(manager.iCloudSyncMode, .none)
    }

    /// Verifies the persistent store descriptions enable automatic lightweight migration.
    func test_persistentStoreDescriptions_enableAutomaticMigration() {
        guard let modelUrl else {
            XCTFail("Missing temporary model URL")
            return
        }

        let storagePath = LocalStoragePath.applicationSupportDirectory(appending: "CoreDataKitTests/\(UUID().uuidString)")
        let manager = CoreDataManager(
            url: modelUrl,
            nameModel: "TestModel",
            databaseName: "LocalStore",
            databaseStorage: storagePath,
            iCloudSyncMode: .none
        )

        guard let description = manager.persistentContainer.persistentStoreDescriptions.first else {
            XCTFail("Missing persistent store description")
            return
        }

        XCTAssertTrue(description.shouldMigrateStoreAutomatically)
        XCTAssertTrue(description.shouldInferMappingModelAutomatically)
    }
}

private extension CoreDataManagerConfigurationTests {
    /// Creates a temporary Core Data model file on disk.
    ///
    /// - Returns: The URL of the created model file.
    func createTemporaryModelUrl() -> URL? {
        let entity = NSEntityDescription()
        entity.name = "TestEntity"
        entity.managedObjectClassName = "NSManagedObject"

        let model = NSManagedObjectModel()
        model.entities = [entity]

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoreDataKitTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            XCTFail("Failed to create temporary directory: \(error)")
            return nil
        }

        let modelUrl = directory.appendingPathComponent("TestModel.mom")
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: model, requiringSecureCoding: true)
            try data.write(to: modelUrl)
            return modelUrl
        } catch {
            XCTFail("Failed to write temporary model to disk: \(error)")
        }
        return nil
    }
}
