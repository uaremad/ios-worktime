//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Rates {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Rates> {
        NSFetchRequest<Rates>(entityName: "Rates")
    }

    @NSManaged var billing_type: String?
    @NSManaged var created_at: Date?
    @NSManaged var currency: String?
    @NSManaged var fixed_amount: NSNumber?
    @NSManaged var hourly_rate: NSNumber?
    @NSManaged var is_default: NSNumber?
    @NSManaged var name: String?
    @NSManaged var shared_profile: NSNumber?
    @NSManaged var updated_at: Date?
    @NSManaged var valid_from: Date?
    @NSManaged var valid_to: Date?
    @NSManaged var activity: Activities?
    @NSManaged var invoiceLines: Set<InvoiceLine>?
    @NSManaged var order: Order?
    @NSManaged var profile: Profile?
    @NSManaged var timerecords: Set<TimeRecords>?
}

public extension Rates {
    @objc(addInvoiceLinesObject:)
    @NSManaged func addToInvoiceLines(_ value: InvoiceLine)

    @objc(removeInvoiceLinesObject:)
    @NSManaged func removeFromInvoiceLines(_ value: InvoiceLine)

    @objc(addInvoiceLines:)
    @NSManaged func addToInvoiceLines(_ values: NSSet)

    @objc(removeInvoiceLines:)
    @NSManaged func removeFromInvoiceLines(_ values: NSSet)

    @objc(addTimerecordsObject:)
    @NSManaged func addToTimerecords(_ value: TimeRecords)

    @objc(removeTimerecordsObject:)
    @NSManaged func removeFromTimerecords(_ value: TimeRecords)

    @objc(addTimerecords:)
    @NSManaged func addToTimerecords(_ values: NSSet)

    @objc(removeTimerecords:)
    @NSManaged func removeFromTimerecords(_ values: NSSet)
}

extension Rates: Identifiable {}
