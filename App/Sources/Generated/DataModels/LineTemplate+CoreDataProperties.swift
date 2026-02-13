//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension LineTemplate {
    @nonobjc class func fetchRequest() -> NSFetchRequest<LineTemplate> {
        NSFetchRequest<LineTemplate>(entityName: "LineTemplate")
    }

    @NSManaged var billing_type: String?
    @NSManaged var currency: String?
    @NSManaged var default_description: String?
    @NSManaged var default_quantity: NSNumber?
    @NSManaged var default_tax_rate: NSNumber?
    @NSManaged var default_title: String?
    @NSManaged var default_unit_price: NSNumber?
    @NSManaged var is_active: NSNumber?
    @NSManaged var name: String?
    @NSManaged var shared_profile: NSNumber?
    @NSManaged var unit: String?
    @NSManaged var profile: Profile?
    @NSManaged var client: Client?
    @NSManaged var order: Order?
    @NSManaged var invoiceLines: Set<InvoiceLine>?
}

public extension LineTemplate {
    @objc(addInvoiceLinesObject:)
    @NSManaged func addToInvoiceLines(_ value: InvoiceLine)

    @objc(removeInvoiceLinesObject:)
    @NSManaged func removeFromInvoiceLines(_ value: InvoiceLine)

    @objc(addInvoiceLines:)
    @NSManaged func addToInvoiceLines(_ values: NSSet)

    @objc(removeInvoiceLines:)
    @NSManaged func removeFromInvoiceLines(_ values: NSSet)
}

extension LineTemplate: Identifiable {}
