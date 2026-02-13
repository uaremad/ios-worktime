//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Absence {
    @discardableResult
    static func insert(into context: NSManagedObjectContext) -> Absence {
        Absence(context: context)
    }

    func deleteEntry() {
        managedObjectContext?.delete(self)
    }
}
