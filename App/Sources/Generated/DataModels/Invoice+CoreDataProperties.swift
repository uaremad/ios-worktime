//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Invoice {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Invoice> {
        NSFetchRequest<Invoice>(entityName: "Invoice")
    }

    @NSManaged var created_at: Date?
    @NSManaged var currency: String?
    @NSManaged var due_date: Date?
    @NSManaged var footer_text: String?
    @NSManaged var issue_date: Date?
    @NSManaged var jurisdiction: String?
    @NSManaged var notes: String?
    @NSManaged var number: String?
    @NSManaged var paid_at: Date?
    @NSManaged var payment_terms: String?
    @NSManaged var payment_reference: String?
    @NSManaged var period_end: Date?
    @NSManaged var period_start: Date?
    @NSManaged var po_number: String?
    @NSManaged var status: String?
    @NSManaged var tax_mode: String?
    @NSManaged var updated_at: Date?
    @NSManaged var profile: Profile?
    @NSManaged var client: Client?
    @NSManaged var issuer: Issuer?
    @NSManaged var lines: Set<InvoiceLine>?
}

public extension Invoice {
    @objc(addLinesObject:)
    @NSManaged func addToLines(_ value: InvoiceLine)

    @objc(removeLinesObject:)
    @NSManaged func removeFromLines(_ value: InvoiceLine)

    @objc(addLines:)
    @NSManaged func addToLines(_ values: NSSet)

    @objc(removeLines:)
    @NSManaged func removeFromLines(_ values: NSSet)
}

extension Invoice: Identifiable {}
