//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Client {
    @discardableResult
    static func insert(into context: NSManagedObjectContext) -> Client {
        Client(context: context)
    }

    func deleteEntry() {
        managedObjectContext?.delete(self)
    }
}
