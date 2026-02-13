//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension TimeRecordChange {
    @discardableResult
    static func insert(into context: NSManagedObjectContext) -> TimeRecordChange {
        TimeRecordChange(context: context)
    }

    func deleteEntry() {
        managedObjectContext?.delete(self)
    }
}
