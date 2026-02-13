//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// Represents the type of persistent store.
public enum PersistentStoreType {
    /// Represents the value for NSSQLiteStoreType.
    case sqLite

    /// Represents the value for NSBinary1StoreType.
    case binary

    /// Represents the value for NSInMemoryStoreType.
    case inMemory

    /// The value of the Core Data string constants corresponding to each case.
    var stringValue: String {
        switch self {
        case .sqLite:
            NSSQLiteStoreType
        case .binary:
            NSBinaryStoreType
        case .inMemory:
            NSInMemoryStoreType
        }
    }
}
