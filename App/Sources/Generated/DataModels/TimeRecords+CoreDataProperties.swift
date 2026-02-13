//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension TimeRecords {
    @nonobjc class func fetchRequest() -> NSFetchRequest<TimeRecords> {
        NSFetchRequest<TimeRecords>(entityName: "TimeRecords")
    }

    @NSManaged var approval_note: String?
    @NSManaged var approval_status: String?
    @NSManaged var approved_at: Date?
    @NSManaged var approved_by_name: String?
    @NSManaged var attested: NSNumber?
    @NSManaged var attested_at: Date?
    @NSManaged var attested_by_name: String?
    @NSManaged var billing_status: String?
    @NSManaged var billing_type_snapshot: String?
    @NSManaged var break_minutes: NSNumber?
    @NSManaged var created_at: Date?
    @NSManaged var currency_snapshot: String?
    @NSManaged var duration_minutes: NSNumber?
    @NSManaged var end_time: Date?
    @NSManaged var fixed_amount_snapshot: NSNumber?
    @NSManaged var hourly_rate_snapshot: NSNumber?
    @NSManaged var invoiced_at: Date?
    @NSManaged var is_running: NSNumber?
    @NSManaged var locked: NSNumber?
    @NSManaged var net_minutes: NSNumber?
    @NSManaged var notice: String?
    @NSManaged var start_time: Date?
    @NSManaged var work_date: Date?
    @NSManaged var activity: Activities?
    @NSManaged var attachments: Set<Attachment>?
    @NSManaged var changes: Set<TimeRecordChange>?
    @NSManaged var approved_by: Profile?
    @NSManaged var costCentre: CostCentre?
    @NSManaged var invoiceLine: InvoiceLine?
    @NSManaged var order: Order?
    @NSManaged var profile: Profile?
    @NSManaged var rate: Rates?
}

public extension TimeRecords {
    @objc(addAttachmentsObject:)
    @NSManaged func addToAttachments(_ value: Attachment)

    @objc(removeAttachmentsObject:)
    @NSManaged func removeFromAttachments(_ value: Attachment)

    @objc(addAttachments:)
    @NSManaged func addToAttachments(_ values: NSSet)

    @objc(removeAttachments:)
    @NSManaged func removeFromAttachments(_ values: NSSet)

    @objc(addChangesObject:)
    @NSManaged func addToChanges(_ value: TimeRecordChange)

    @objc(removeChangesObject:)
    @NSManaged func removeFromChanges(_ value: TimeRecordChange)

    @objc(addChanges:)
    @NSManaged func addToChanges(_ values: NSSet)

    @objc(removeChanges:)
    @NSManaged func removeFromChanges(_ values: NSSet)
}

extension TimeRecords: Identifiable {}
