//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// An extension providing additional functionality to the `CoreDataManager` class.
extension CoreDataManager {
    /// A structure representing a transformer for persistent stores.
    struct StoreTransformer {
        /// A closure that transforms the persistent store description.
        let transform: (PersistentStoreType, NSPersistentStoreDescription) -> Void

        /// Initializes the store transformer with the given transformation closure.
        ///
        /// - Parameter transform: The transformation closure.
        public init(_ transform: @escaping (PersistentStoreType, NSPersistentStoreDescription) -> Void) {
            self.transform = transform
        }
    }
}
