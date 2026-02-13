//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension TimeRecordChange {
    @nonobjc class func fetchRequest() -> NSFetchRequest<TimeRecordChange> {
        NSFetchRequest<TimeRecordChange>(entityName: "TimeRecordChange")
    }

    @NSManaged var changed_at: Date?
    @NSManaged var changed_by_name: String?
    @NSManaged var field_name: String?
    @NSManaged var new_value: String?
    @NSManaged var old_value: String?
    @NSManaged var timeRecord: TimeRecords?
}

extension TimeRecordChange: Identifiable {}
