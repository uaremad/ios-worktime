//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import XCTest
@testable import CoreDataKit

/// Covers CoreDataKit utilities and configuration paths.
final class CoreDataKitCoverageTests: XCTestCase {
    /// Holds a temporary model URL for the current test.
    private var modelUrl: URL?

    /// Sets up a temporary Core Data model for each test.
    override func setUp() {
        super.setUp()
        modelUrl = TestModelFactory.writeModelToTemporaryUrl(
            model: TestModelFactory.makeModel(),
            name: "TestModel"
        )
    }

    /// Cleans up temporary resources after each test.
    override func tearDown() {
        if let modelUrl {
            try? FileManager.default.removeItem(at: modelUrl.deletingLastPathComponent())
        }
        modelUrl = nil
        CoreDataManager.shared = nil
        super.tearDown()
    }

    /// Verifies PersistentStoreType maps to expected Core Data store strings.
    func test_persistentStoreType_stringValues() {
        XCTAssertEqual(PersistentStoreType.sqLite.stringValue, NSSQLiteStoreType)
        XCTAssertEqual(PersistentStoreType.binary.stringValue, NSBinaryStoreType)
        XCTAssertEqual(PersistentStoreType.inMemory.stringValue, NSInMemoryStoreType)
    }

    /// Verifies CoreDataManager can load a model from a URL.
    func test_loadModel_withUrl_returnsModel() {
        guard let modelUrl else {
            XCTFail("Missing model URL")
            return
        }

        let model = CoreDataManager.loadModel(bundle: nil, use: modelUrl, modelName: "TestModel")
        XCTAssertNotNil(model)
    }

    /// Verifies saveIfNeeded returns false when no changes exist.
    func test_saveIfNeeded_returnsFalseWhenNoChanges() throws {
        let container = try TestModelFactory.makeInMemoryContainer(model: TestModelFactory.makeModel())
        let context = container.viewContext

        let didSave = try context.saveIfNeeded()
        XCTAssertFalse(didSave)
    }

    /// Verifies saveIfNeeded saves and returns true when changes exist.
    func test_saveIfNeeded_savesChanges() throws {
        let model = TestModelFactory.makeModel()
        let container = try TestModelFactory.makeInMemoryContainer(model: model)
        let context = container.viewContext

        let entity = model.entities[0]
        _ = NSManagedObject(entity: entity, insertInto: context)

        let didSave = try context.saveIfNeeded()
        XCTAssertTrue(didSave)
    }

    /// Verifies CoreDataManager config helpers return expected values.
    func test_coreDataManager_configProperties() {
        guard let modelUrl else {
            XCTFail("Missing model URL")
            return
        }

        let manager = TestModelFactory.makeManager(
            modelUrl: modelUrl,
            databaseName: "UnitTestStore",
            storagePath: TestModelFactory.makeStoragePath()
        )
        CoreDataManager.shared = manager

        XCTAssertEqual(CoreDataManager.storageName, "UnitTestStore")
        XCTAssertGreaterThanOrEqual(CoreDataManager.storageSize, 0)
        XCTAssertNotNil(CoreDataManager.lastSyncDate)

        XCTAssertFalse(CoreDataManager.isCloud)
        manager.iCloudSyncMode = .container(containerID: "iCloud.test.container", scope: .private)
        XCTAssertTrue(CoreDataManager.isCloud)
    }

    /// Verifies injected values resolve the shared CoreDataManager.
    func test_injectedValues_resolveSharedManager() {
        guard let modelUrl else {
            XCTFail("Missing model URL")
            return
        }

        let manager = TestModelFactory.makeManager(
            modelUrl: modelUrl,
            databaseName: "InjectionStore",
            storagePath: TestModelFactory.makeStoragePath()
        )
        CoreDataManager.shared = manager

        let injectedValues = CoreDataManagerInjectedValues()
        XCTAssertNotNil(injectedValues.persistentContainer)
        XCTAssertEqual(injectedValues.viewContext, manager.viewContext)
        XCTAssertEqual(injectedValues.backgroundContext, manager.backgroundContext)
        XCTAssertNotNil(injectedValues.newBackgroundContext)
        XCTAssertNotNil(injectedValues.persistentStore)
        XCTAssertNil(injectedValues.binaryStore)
        XCTAssertNil(injectedValues.temporaryStore)

        let consumer = InjectionConsumer()
        XCTAssertEqual(consumer.viewContext, manager.viewContext)
    }

    /// Verifies store transformer executes its closure.
    func test_storeTransformer_executesClosure() {
        var didCall = false
        let transformer = CoreDataManager.StoreTransformer { _, _ in
            didCall = true
        }
        transformer.transform(.sqLite, NSPersistentStoreDescription())
        XCTAssertTrue(didCall)
    }

    /// Verifies CloudKit options transformer executes its closure.
    func test_cloudKitOptionsTransformer_executesClosure() {
        var didCall = false
        let transformer = CloudKitOptionsTransformer { _ in
            didCall = true
        }
        transformer.transform(NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.test.container"))
        XCTAssertTrue(didCall)
    }

    /// Verifies migration returns without error when no state change is needed.
    func test_migrationService_returnsWhenStateUnchanged() async {
        let request = ICloudSyncMigrationService.MigrationRequest(
            fromICloudEnabled: true,
            toICloudEnabled: true,
            context: nil,
            modelName: "MissingModel",
            storagePath: TestModelFactory.makeStoragePath(),
            localDatabaseName: "Local",
            cloudDatabaseName: "Cloud",
            cloudContainerIdentifier: "iCloud.test.container"
        )

        do {
            try await ICloudSyncMigrationService.synchronizeStores(request: request)
        } catch {
            XCTFail("Expected no error, but received \(error)")
        }
    }

    /// Verifies migration throws when CloudKit container identifier is missing.
    func test_migrationService_missingContainerIdThrows() async {
        let request = ICloudSyncMigrationService.MigrationRequest(
            fromICloudEnabled: false,
            toICloudEnabled: true,
            context: nil,
            modelName: "MissingModel",
            storagePath: TestModelFactory.makeStoragePath(),
            localDatabaseName: "Local",
            cloudDatabaseName: "Cloud",
            cloudContainerIdentifier: ""
        )

        do {
            try await ICloudSyncMigrationService.synchronizeStores(request: request)
            XCTFail("Expected missingCloudContainerIdentifier error")
        } catch {
            switch error {
            case .missingCloudContainerIdentifier:
                XCTAssertTrue(true)
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    /// Verifies migration throws when the Core Data model is missing.
    func test_migrationService_missingModelThrows() async {
        let request = ICloudSyncMigrationService.MigrationRequest(
            fromICloudEnabled: true,
            toICloudEnabled: false,
            context: nil,
            modelName: "MissingModel",
            storagePath: TestModelFactory.makeStoragePath(),
            localDatabaseName: "Local",
            cloudDatabaseName: "Cloud",
            cloudContainerIdentifier: "iCloud.test.container"
        )

        do {
            try await ICloudSyncMigrationService.synchronizeStores(request: request)
            XCTFail("Expected missingModel error")
        } catch {
            switch error {
            case .missingModel:
                XCTAssertTrue(true)
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    /// Verifies initialize and reload create persistent containers.
    func test_initializeAndReload_createContainers() {
        guard let modelUrl else {
            XCTFail("Missing model URL")
            return
        }

        let manager = TestModelFactory.makeManager(
            modelUrl: modelUrl,
            databaseName: "ReloadStore",
            storagePath: TestModelFactory.makeStoragePath()
        )

        var initializeCalled = false
        manager.initialize { container in
            initializeCalled = true
            XCTAssertNotNil(container.viewContext)
        }

        var reloadCalled = false
        manager.reloadPersistentContainer { container in
            reloadCalled = true
            XCTAssertNotNil(container.viewContext)
        }

        XCTAssertTrue(initializeCalled)
        XCTAssertTrue(reloadCalled)
    }
}

private extension CoreDataKitCoverageTests {
    /// Provides a property wrapper consumer for injection tests.
    struct InjectionConsumer {
        /// Injects the shared view context.
        @CoreDataManagerInjected(\.viewContext) var viewContext: NSManagedObjectContext

        /// Creates a new injection consumer.
        init() {
            _viewContext = CoreDataManagerInjected(\.viewContext)
        }
    }

    /// Creates Core Data models and containers for unit tests.
    enum TestModelFactory {
        /// Builds a simple model with one entity.
        ///
        /// - Returns: A simple managed object model.
        static func makeModel() -> NSManagedObjectModel {
            let entity = NSEntityDescription()
            entity.name = "TestEntity"
            entity.managedObjectClassName = "NSManagedObject"

            let model = NSManagedObjectModel()
            model.entities = [entity]
            return model
        }

        /// Creates a temporary folder URL for test data.
        ///
        /// - Returns: A temporary directory URL.
        static func makeTemporaryDirectory() -> URL {
            FileManager.default.temporaryDirectory
                .appendingPathComponent("CoreDataKitTests", isDirectory: true)
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
        }

        /// Writes a model to a temporary .mom file.
        ///
        /// - Parameters:
        ///   - model: The managed object model to write.
        ///   - name: The base name for the model file.
        /// - Returns: The file URL of the written model.
        static func writeModelToTemporaryUrl(
            model: NSManagedObjectModel,
            name: String
        ) -> URL? {
            let directory = makeTemporaryDirectory()
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                XCTFail("Failed to create temporary directory: \(error)")
                return nil
            }

            let modelUrl = directory.appendingPathComponent("\(name).mom")
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: model, requiringSecureCoding: true)
                try data.write(to: modelUrl)
                return modelUrl
            } catch {
                XCTFail("Failed to write temporary model to disk: \(error)")
                return nil
            }
        }

        /// Creates a Core Data manager for unit tests.
        ///
        /// - Parameters:
        ///   - modelUrl: The model URL to load.
        ///   - databaseName: The database name to use.
        ///   - storagePath: The storage path for the SQLite file.
        /// - Returns: A configured CoreDataManager instance.
        static func makeManager(
            modelUrl: URL,
            databaseName: String,
            storagePath: LocalStoragePath
        ) -> CoreDataManager {
            CoreDataManager(
                url: modelUrl,
                nameModel: "TestModel",
                databaseName: databaseName,
                databaseStorage: storagePath,
                iCloudSyncMode: .none
            )
        }

        /// Creates an in-memory persistent container for tests.
        ///
        /// - Parameter model: The model to use.
        /// - Returns: A loaded NSPersistentContainer.
        static func makeInMemoryContainer(model: NSManagedObjectModel) throws -> NSPersistentContainer {
            let container = NSPersistentContainer(name: "TestContainer", managedObjectModel: model)
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]

            let expectation = XCTestExpectation(description: "Persistent store loaded")
            container.loadPersistentStores { _, error in
                XCTAssertNil(error)
                expectation.fulfill()
            }
            XCTWaiter().wait(for: [expectation], timeout: 2)
            return container
        }

        /// Builds a storage path for SQLite testing.
        ///
        /// - Returns: A LocalStoragePath using a unique temporary folder.
        static func makeStoragePath() -> LocalStoragePath {
            .applicationSupportDirectory(appending: "CoreDataKitTests/\(UUID().uuidString)")
        }
    }
}
