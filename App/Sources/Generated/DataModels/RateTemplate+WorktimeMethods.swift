//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension RateTemplate {
    /// Inserts a new `RateTemplate` entry into the provided context.
    ///
    /// - Parameter context: The managed object context that will own the inserted object.
    /// - Returns: The inserted `RateTemplate` instance.
    @discardableResult
    static func insert(into context: NSManagedObjectContext) -> RateTemplate {
        RateTemplate(context: context)
    }

    /// Deletes the receiver from its managed object context.
    ///
    /// If the receiver is not associated with a context, this method is a no-op.
    func deleteEntry() {
        managedObjectContext?.delete(self)
    }
}
