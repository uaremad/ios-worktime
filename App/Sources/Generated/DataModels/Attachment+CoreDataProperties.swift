//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Attachment {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Attachment> {
        NSFetchRequest<Attachment>(entityName: "Attachment")
    }

    @NSManaged var created_at: Date?
    @NSManaged var filename: String?
    @NSManaged var kind: String?
    @NSManaged var local_path: String?
    @NSManaged var mime_type: String?
    @NSManaged var storage_key: String?
    @NSManaged var timeRecord: TimeRecords?
}

extension Attachment: Identifiable {}
