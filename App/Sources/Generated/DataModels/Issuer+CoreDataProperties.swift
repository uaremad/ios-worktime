//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Issuer {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Issuer> {
        NSFetchRequest<Issuer>(entityName: "Issuer")
    }

    @NSManaged var bank_account_number: String?
    @NSManaged var address: String?
    @NSManaged var bank_bic: String?
    @NSManaged var bank_iban: String?
    @NSManaged var bank_routing_number: String?
    @NSManaged var email: String?
    @NSManaged var is_active: NSNumber?
    @NSManaged var name: String?
    @NSManaged var payment_method: String?
    @NSManaged var shared_profile: NSNumber?
    @NSManaged var tax_id: String?
    @NSManaged var type: String?
    @NSManaged var vat_id: String?
    @NSManaged var profile: Profile?
    @NSManaged var invoices: Set<Invoice>?
}

public extension Issuer {
    @objc(addInvoicesObject:)
    @NSManaged func addToInvoices(_ value: Invoice)

    @objc(removeInvoicesObject:)
    @NSManaged func removeFromInvoices(_ value: Invoice)

    @objc(addInvoices:)
    @NSManaged func addToInvoices(_ values: NSSet)

    @objc(removeInvoices:)
    @NSManaged func removeFromInvoices(_ values: NSSet)
}

extension Issuer: Identifiable {}
