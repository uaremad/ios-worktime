//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension Configuration {
    /// Creates a fetch request for `Configuration` items.
    @nonobjc class func fetchRequest() -> NSFetchRequest<Configuration> {
        NSFetchRequest<Configuration>(entityName: "Configuration")
    }

    /// Stores the configuration key.
    @NSManaged var config_key: String?

    /// Stores the configuration value.
    @NSManaged var config_value: String?

    /// Stores when this configuration row was created.
    @NSManaged var created_at: Date?

    /// Stores when this configuration row was last updated.
    @NSManaged var updated_at: Date?

    /// Stores the optional profile-specific scope.
    @NSManaged var profile: Profile?
}

extension Configuration: Identifiable {}
