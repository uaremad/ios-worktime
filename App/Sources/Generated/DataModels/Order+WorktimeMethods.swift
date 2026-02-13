//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Order {
    /// Inserts a new `Order` entry into the provided context.
    @discardableResult
    static func insert(into context: NSManagedObjectContext) -> Order {
        Order(context: context)
    }

    /// Deletes the receiver from its managed object context.
    func deleteEntry() {
        managedObjectContext?.delete(self)
    }
}
