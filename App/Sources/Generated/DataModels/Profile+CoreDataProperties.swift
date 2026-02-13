//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Profile {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Profile> {
        NSFetchRequest<Profile>(entityName: "Profile")
    }

    @NSManaged var created_at: Date?
    @NSManaged var is_active: NSNumber?
    @NSManaged var name: String?
    @NSManaged var updated_at: Date?
    @NSManaged var uuid: String?
    @NSManaged var activities: Set<Activities>?
    @NSManaged var absences: Set<Absence>?
    @NSManaged var approvedTimeRecords: Set<TimeRecords>?
    @NSManaged var clients: Set<Client>?
    @NSManaged var configurations: Set<Configuration>?
    @NSManaged var costCentres: Set<CostCentre>?
    @NSManaged var invoices: Set<Invoice>?
    @NSManaged var issuers: Set<Issuer>?
    @NSManaged var lineTemplates: Set<LineTemplate>?
    @NSManaged var orders: Set<Order>?
    @NSManaged var rates: Set<Rates>?
    @NSManaged var rateTemplates: Set<RateTemplate>?
    @NSManaged var timeRecords: Set<TimeRecords>?
}

public extension Profile {
    @objc(addActivitiesObject:)
    @NSManaged func addToActivities(_ value: Activities)
    @objc(removeActivitiesObject:)
    @NSManaged func removeFromActivities(_ value: Activities)
    @objc(addActivities:)
    @NSManaged func addToActivities(_ values: NSSet)
    @objc(removeActivities:)
    @NSManaged func removeFromActivities(_ values: NSSet)

    @objc(addAbsencesObject:)
    @NSManaged func addToAbsences(_ value: Absence)
    @objc(removeAbsencesObject:)
    @NSManaged func removeFromAbsences(_ value: Absence)
    @objc(addAbsences:)
    @NSManaged func addToAbsences(_ values: NSSet)
    @objc(removeAbsences:)
    @NSManaged func removeFromAbsences(_ values: NSSet)

    @objc(addApprovedTimeRecordsObject:)
    @NSManaged func addToApprovedTimeRecords(_ value: TimeRecords)
    @objc(removeApprovedTimeRecordsObject:)
    @NSManaged func removeFromApprovedTimeRecords(_ value: TimeRecords)
    @objc(addApprovedTimeRecords:)
    @NSManaged func addToApprovedTimeRecords(_ values: NSSet)
    @objc(removeApprovedTimeRecords:)
    @NSManaged func removeFromApprovedTimeRecords(_ values: NSSet)

    @objc(addClientsObject:)
    @NSManaged func addToClients(_ value: Client)
    @objc(removeClientsObject:)
    @NSManaged func removeFromClients(_ value: Client)
    @objc(addClients:)
    @NSManaged func addToClients(_ values: NSSet)
    @objc(removeClients:)
    @NSManaged func removeFromClients(_ values: NSSet)

    @objc(addConfigurationsObject:)
    @NSManaged func addToConfigurations(_ value: Configuration)
    @objc(removeConfigurationsObject:)
    @NSManaged func removeFromConfigurations(_ value: Configuration)
    @objc(addConfigurations:)
    @NSManaged func addToConfigurations(_ values: NSSet)
    @objc(removeConfigurations:)
    @NSManaged func removeFromConfigurations(_ values: NSSet)

    @objc(addCostCentresObject:)
    @NSManaged func addToCostCentres(_ value: CostCentre)
    @objc(removeCostCentresObject:)
    @NSManaged func removeFromCostCentres(_ value: CostCentre)
    @objc(addCostCentres:)
    @NSManaged func addToCostCentres(_ values: NSSet)
    @objc(removeCostCentres:)
    @NSManaged func removeFromCostCentres(_ values: NSSet)

    @objc(addInvoicesObject:)
    @NSManaged func addToInvoices(_ value: Invoice)
    @objc(removeInvoicesObject:)
    @NSManaged func removeFromInvoices(_ value: Invoice)
    @objc(addInvoices:)
    @NSManaged func addToInvoices(_ values: NSSet)
    @objc(removeInvoices:)
    @NSManaged func removeFromInvoices(_ values: NSSet)

    @objc(addIssuersObject:)
    @NSManaged func addToIssuers(_ value: Issuer)
    @objc(removeIssuersObject:)
    @NSManaged func removeFromIssuers(_ value: Issuer)
    @objc(addIssuers:)
    @NSManaged func addToIssuers(_ values: NSSet)
    @objc(removeIssuers:)
    @NSManaged func removeFromIssuers(_ values: NSSet)

    @objc(addLineTemplatesObject:)
    @NSManaged func addToLineTemplates(_ value: LineTemplate)
    @objc(removeLineTemplatesObject:)
    @NSManaged func removeFromLineTemplates(_ value: LineTemplate)
    @objc(addLineTemplates:)
    @NSManaged func addToLineTemplates(_ values: NSSet)
    @objc(removeLineTemplates:)
    @NSManaged func removeFromLineTemplates(_ values: NSSet)

    @objc(addOrdersObject:)
    @NSManaged func addToOrders(_ value: Order)
    @objc(removeOrdersObject:)
    @NSManaged func removeFromOrders(_ value: Order)
    @objc(addOrders:)
    @NSManaged func addToOrders(_ values: NSSet)
    @objc(removeOrders:)
    @NSManaged func removeFromOrders(_ values: NSSet)

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

    @objc(addTimeRecordsObject:)
    @NSManaged func addToTimeRecords(_ value: TimeRecords)
    @objc(removeTimeRecordsObject:)
    @NSManaged func removeFromTimeRecords(_ value: TimeRecords)
    @objc(addTimeRecords:)
    @NSManaged func addToTimeRecords(_ values: NSSet)
    @objc(removeTimeRecords:)
    @NSManaged func removeFromTimeRecords(_ values: NSSet)
}

extension Profile: Identifiable {}
