//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Client {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Client> {
        NSFetchRequest<Client>(entityName: "Client")
    }

    @NSManaged var address: String?
    @NSManaged var country_code: String?
    @NSManaged var created_at: Date?
    @NSManaged var email: String?
    @NSManaged var external_ref: String?
    @NSManaged var invoice_address: String?
    @NSManaged var invoice_email: String?
    @NSManaged var is_active: NSNumber?
    @NSManaged var name: String?
    @NSManaged var sales_tax_exempt: NSNumber?
    @NSManaged var sales_tax_id: String?
    @NSManaged var shared_profile: NSNumber?
    @NSManaged var tax_id: String?
    @NSManaged var updated_at: Date?
    @NSManaged var vat_id: String?
    @NSManaged var profile: Profile?
    @NSManaged var orders: Set<Order>?
    @NSManaged var invoices: Set<Invoice>?
    @NSManaged var lineTemplates: Set<LineTemplate>?
}

public extension Client {
    @objc(addOrdersObject:)
    @NSManaged func addToOrders(_ value: Order)
    @objc(removeOrdersObject:)
    @NSManaged func removeFromOrders(_ value: Order)
    @objc(addOrders:)
    @NSManaged func addToOrders(_ values: NSSet)
    @objc(removeOrders:)
    @NSManaged func removeFromOrders(_ values: NSSet)

    @objc(addInvoicesObject:)
    @NSManaged func addToInvoices(_ value: Invoice)
    @objc(removeInvoicesObject:)
    @NSManaged func removeFromInvoices(_ value: Invoice)
    @objc(addInvoices:)
    @NSManaged func addToInvoices(_ values: NSSet)
    @objc(removeInvoices:)
    @NSManaged func removeFromInvoices(_ values: NSSet)

    @objc(addLineTemplatesObject:)
    @NSManaged func addToLineTemplates(_ value: LineTemplate)
    @objc(removeLineTemplatesObject:)
    @NSManaged func removeFromLineTemplates(_ value: LineTemplate)
    @objc(addLineTemplates:)
    @NSManaged func addToLineTemplates(_ values: NSSet)
    @objc(removeLineTemplates:)
    @NSManaged func removeFromLineTemplates(_ values: NSSet)
}

extension Client: Identifiable {}
