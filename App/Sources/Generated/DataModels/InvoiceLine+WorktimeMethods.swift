//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension InvoiceLine {
    @discardableResult
    static func insert(into context: NSManagedObjectContext) -> InvoiceLine {
        InvoiceLine(context: context)
    }

    func deleteEntry() {
        managedObjectContext?.delete(self)
    }
}
