//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Rates {
    /// Inserts a new `Rates` entry into the provided context.
    ///
    /// - Parameter context: The managed object context that will own the inserted object.
    /// - Returns: The inserted `Rates` instance.
    @discardableResult
    static func insert(into context: NSManagedObjectContext) -> Rates {
        Rates(context: context)
    }

    /// Deletes the receiver from its managed object context.
    ///
    /// If the receiver is not associated with a context, this method is a no-op.
    func deleteEntry() {
        managedObjectContext?.delete(self)
    }
}
