//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// An extension providing additional functionality to the `NSManagedObjectContext` class.
public extension NSManagedObjectContext {
    /// Only performs a save if there are changes to commit.
    ///
    /// - Returns: `true` if a save was needed. Otherwise, `false`.
    @discardableResult func saveIfNeeded() throws -> Bool {
        guard hasChanges else { return false }
        try save()
        return true
    }
}
