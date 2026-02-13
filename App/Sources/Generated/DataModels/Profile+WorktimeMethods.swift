//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Profile {
    /// Inserts a new `Profile` entry into the provided context.
    @discardableResult
    static func insert(into context: NSManagedObjectContext) -> Profile {
        Profile(context: context)
    }

    /// Deletes the receiver from its managed object context.
    func deleteEntry() {
        managedObjectContext?.delete(self)
    }
}
