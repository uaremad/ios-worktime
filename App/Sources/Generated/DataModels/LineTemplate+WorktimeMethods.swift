//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension LineTemplate {
    @discardableResult
    static func insert(into context: NSManagedObjectContext) -> LineTemplate {
        LineTemplate(context: context)
    }

    func deleteEntry() {
        managedObjectContext?.delete(self)
    }
}
