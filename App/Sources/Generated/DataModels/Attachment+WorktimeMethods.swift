//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Attachment {
    @discardableResult
    static func insert(into context: NSManagedObjectContext) -> Attachment {
        Attachment(context: context)
    }

    func deleteEntry() {
        managedObjectContext?.delete(self)
    }
}
