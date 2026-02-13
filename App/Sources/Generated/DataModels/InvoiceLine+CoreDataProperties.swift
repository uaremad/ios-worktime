//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension InvoiceLine {
    @nonobjc class func fetchRequest() -> NSFetchRequest<InvoiceLine> {
        NSFetchRequest<InvoiceLine>(entityName: "InvoiceLine")
    }

    @NSManaged var amount: NSNumber?
    @NSManaged var billing_type: String?
    @NSManaged var created_at: Date?
    @NSManaged var description_text: String?
    @NSManaged var quantity: NSNumber?
    @NSManaged var sort_index: NSNumber?
    @NSManaged var source_type: String?
    @NSManaged var tax_rate: NSNumber?
    @NSManaged var title: String?
    @NSManaged var unit: String?
    @NSManaged var unit_price: NSNumber?
    @NSManaged var updated_at: Date?
    @NSManaged var invoice: Invoice?
    @NSManaged var order: Order?
    @NSManaged var activity: Activities?
    @NSManaged var rate: Rates?
    @NSManaged var template: LineTemplate?
    @NSManaged var timeRecords: Set<TimeRecords>?
}

public extension InvoiceLine {
    @objc(addTimeRecordsObject:)
    @NSManaged func addToTimeRecords(_ value: TimeRecords)

    @objc(removeTimeRecordsObject:)
    @NSManaged func removeFromTimeRecords(_ value: TimeRecords)

    @objc(addTimeRecords:)
    @NSManaged func addToTimeRecords(_ values: NSSet)

    @objc(removeTimeRecords:)
    @NSManaged func removeFromTimeRecords(_ values: NSSet)
}

extension InvoiceLine: Identifiable {}
