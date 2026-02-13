//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Invoice {
    @discardableResult
    static func insert(into context: NSManagedObjectContext) -> Invoice {
        Invoice(context: context)
    }

    func deleteEntry() {
        managedObjectContext?.delete(self)
    }
}
