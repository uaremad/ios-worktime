//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Absence {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Absence> {
        NSFetchRequest<Absence>(entityName: "Absence")
    }

    @NSManaged var created_at: Date?
    @NSManaged var end_date: Date?
    @NSManaged var minutes: NSNumber?
    @NSManaged var notice: String?
    @NSManaged var start_date: Date?
    @NSManaged var type: String?
    @NSManaged var updated_at: Date?
    @NSManaged var profile: Profile?
}

extension Absence: Identifiable {}
