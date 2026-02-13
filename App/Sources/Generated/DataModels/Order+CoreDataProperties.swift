//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Order {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Order> {
        NSFetchRequest<Order>(entityName: "Order")
    }

    @NSManaged var code: String?
    @NSManaged var created_at: Date?
    @NSManaged var is_active: NSNumber?
    @NSManaged var name: String?
    @NSManaged var notice: String?
    @NSManaged var shared_profile: NSNumber?
    @NSManaged var updated_at: Date?
    @NSManaged var uuid: UUID?
    @NSManaged var valid_from: Date?
    @NSManaged var valid_to: Date?
    @NSManaged var costCentre: CostCentre?
    @NSManaged var profile: Profile?
    @NSManaged var client: Client?
    @NSManaged var rates: Set<Rates>?
    @NSManaged var timerecords: Set<TimeRecords>?
    @NSManaged var invoiceLines: Set<InvoiceLine>?
    @NSManaged var lineTemplates: Set<LineTemplate>?
}

public extension Order {
    @objc(addRatesObject:)
    @NSManaged func addToRates(_ value: Rates)
    @objc(removeRatesObject:)
    @NSManaged func removeFromRates(_ value: Rates)
    @objc(addRates:)
    @NSManaged func addToRates(_ values: NSSet)
    @objc(removeRates:)
    @NSManaged func removeFromRates(_ values: NSSet)

    @objc(addTimerecordsObject:)
    @NSManaged func addToTimerecords(_ value: TimeRecords)
    @objc(removeTimerecordsObject:)
    @NSManaged func removeFromTimerecords(_ value: TimeRecords)
    @objc(addTimerecords:)
    @NSManaged func addToTimerecords(_ values: NSSet)
    @objc(removeTimerecords:)
    @NSManaged func removeFromTimerecords(_ values: NSSet)

    @objc(addInvoiceLinesObject:)
    @NSManaged func addToInvoiceLines(_ value: InvoiceLine)
    @objc(removeInvoiceLinesObject:)
    @NSManaged func removeFromInvoiceLines(_ value: InvoiceLine)
    @objc(addInvoiceLines:)
    @NSManaged func addToInvoiceLines(_ values: NSSet)
    @objc(removeInvoiceLines:)
    @NSManaged func removeFromInvoiceLines(_ values: NSSet)

    @objc(addLineTemplatesObject:)
    @NSManaged func addToLineTemplates(_ value: LineTemplate)
    @objc(removeLineTemplatesObject:)
    @NSManaged func removeFromLineTemplates(_ value: LineTemplate)
    @objc(addLineTemplates:)
    @NSManaged func addToLineTemplates(_ values: NSSet)
    @objc(removeLineTemplates:)
    @NSManaged func removeFromLineTemplates(_ values: NSSet)
}

extension Order: Identifiable {}
