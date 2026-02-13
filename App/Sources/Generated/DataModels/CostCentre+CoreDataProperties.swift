//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension CostCentre {
    @nonobjc class func fetchRequest() -> NSFetchRequest<CostCentre> {
        NSFetchRequest<CostCentre>(entityName: "CostCentre")
    }

    @NSManaged var external_ref: String?
    @NSManaged var name: String?
    @NSManaged var notice: String?
    @NSManaged var shared_profile: NSNumber?
    @NSManaged var profile: Profile?
    @NSManaged var orders: Set<Order>?
    @NSManaged var timerecords: Set<TimeRecords>?
}

public extension CostCentre {
    @objc(addOrdersObject:)
    @NSManaged func addToOrders(_ value: Order)

    @objc(removeOrdersObject:)
    @NSManaged func removeFromOrders(_ value: Order)

    @objc(addOrders:)
    @NSManaged func addToOrders(_ values: NSSet)

    @objc(removeOrders:)
    @NSManaged func removeFromOrders(_ values: NSSet)

    @objc(addTimerecordsObject:)
    @NSManaged func addToTimerecords(_ value: TimeRecords)

    @objc(removeTimerecordsObject:)
    @NSManaged func removeFromTimerecords(_ value: TimeRecords)

    @objc(addTimerecords:)
    @NSManaged func addToTimerecords(_ values: NSSet)

    @objc(removeTimerecords:)
    @NSManaged func removeFromTimerecords(_ values: NSSet)
}

extension CostCentre: Identifiable {}
