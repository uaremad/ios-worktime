//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension RateTemplate {
    @nonobjc class func fetchRequest() -> NSFetchRequest<RateTemplate> {
        NSFetchRequest<RateTemplate>(entityName: "RateTemplate")
    }

    @NSManaged var billing_type: String?
    @NSManaged var created_at: Date?
    @NSManaged var currency: String?
    @NSManaged var fixed_amount: NSNumber?
    @NSManaged var hourly_rate: NSNumber?
    @NSManaged var is_active: NSNumber?
    @NSManaged var name: String?
    @NSManaged var shared_profile: NSNumber?
    @NSManaged var updated_at: Date?
    @NSManaged var valid_from: Date?
    @NSManaged var valid_to: Date?
    @NSManaged var activity: Activities?
    @NSManaged var profile: Profile?
}

extension RateTemplate: Identifiable {}
