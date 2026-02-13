//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData

// Injected protocol of the key
protocol InjectionKey {
    associatedtype Value
    static var currentValue: Self.Value { get set }
}

// Storage
public struct CoreDataManagerInjectedValues {
    private static var current = CoreDataManagerInjectedValues()

    static subscript<T>(_ keyPath: KeyPath<CoreDataManagerInjectedValues, T>) -> T { current[keyPath: keyPath] }
}

@propertyWrapper
public struct CoreDataManagerInjected<T> {
    private let keyPath: KeyPath<CoreDataManagerInjectedValues, T>

    public var wrappedValue: T { CoreDataManagerInjectedValues[keyPath] }

    public init(_ keyPath: KeyPath<CoreDataManagerInjectedValues, T>) {
        guard CoreDataManager.shared != nil else {
            fatalError("The repository has not been initialized. Create a new instance with CoreDataManager.")
        }
        self.keyPath = keyPath
    }
}

public extension CoreDataManagerInjectedValues {
    var persistentContainer: NSPersistentContainer {
        guard let shared = CoreDataManager.shared else {
            fatalError("No shared CoreDataManager")
        }
        return shared.persistentContainer
    }

    var viewContext: NSManagedObjectContext {
        guard let shared = CoreDataManager.shared else {
            fatalError("No shared CoreDataManager")
        }
        return shared.viewContext
    }

    var backgroundContext: NSManagedObjectContext {
        guard let shared = CoreDataManager.shared else {
            fatalError("No shared CoreDataManager")
        }
        return shared.backgroundContext
    }

    var newBackgroundContext: NSManagedObjectContext {
        guard let shared = CoreDataManager.shared else {
            fatalError("No shared CoreDataManager")
        }
        return shared.persistentContainer.newBackgroundContext()
    }

    var persistentStore: NSPersistentStore? {
        guard let shared = CoreDataManager.shared else {
            fatalError("No shared CoreDataManager")
        }
        return shared.listOfPersistentStores.first(where: { $0.type == NSSQLiteStoreType })
    }

    var binaryStore: NSPersistentStore? {
        guard let shared = CoreDataManager.shared else {
            fatalError("No shared CoreDataManager")
        }
        return shared.listOfPersistentStores.first(where: { $0.type == NSBinaryStoreType })
    }

    var temporaryStore: NSPersistentStore? {
        guard let shared = CoreDataManager.shared else {
            fatalError("No shared CoreDataManager")
        }
        return shared.listOfPersistentStores.first(where: { $0.type == NSInMemoryStoreType })
    }
}
