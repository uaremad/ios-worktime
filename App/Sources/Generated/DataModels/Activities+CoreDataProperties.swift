//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Activities {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Activities> {
        NSFetchRequest<Activities>(entityName: "Activities")
    }

    @NSManaged var is_active: NSNumber?
    @NSManaged var name: String?
    @NSManaged var shared_profile: NSNumber?
    @NSManaged var profile: Profile?
    @NSManaged var rates: Set<Rates>?
    @NSManaged var rateTemplates: Set<RateTemplate>?
    @NSManaged var timerecords: Set<TimeRecords>?
    @NSManaged var invoiceLines: Set<InvoiceLine>?
}

public extension Activities {
    @objc(addRatesObject:)
    @NSManaged func addToRates(_ value: Rates)

    @objc(removeRatesObject:)
    @NSManaged func removeFromRates(_ value: Rates)

    @objc(addRates:)
    @NSManaged func addToRates(_ values: NSSet)

    @objc(removeRates:)
    @NSManaged func removeFromRates(_ values: NSSet)

    @objc(addRateTemplatesObject:)
    @NSManaged func addToRateTemplates(_ value: RateTemplate)

    @objc(removeRateTemplatesObject:)
    @NSManaged func removeFromRateTemplates(_ value: RateTemplate)

    @objc(addRateTemplates:)
    @NSManaged func addToRateTemplates(_ values: NSSet)

    @objc(removeRateTemplates:)
    @NSManaged func removeFromRateTemplates(_ values: NSSet)

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
}

extension Activities: Identifiable {}
