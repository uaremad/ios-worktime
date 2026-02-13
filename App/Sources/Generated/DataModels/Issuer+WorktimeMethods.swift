//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Issuer {
    @discardableResult
    static func insert(into context: NSManagedObjectContext) -> Issuer {
        Issuer(context: context)
    }

    func deleteEntry() {
        managedObjectContext?.delete(self)
    }
}
