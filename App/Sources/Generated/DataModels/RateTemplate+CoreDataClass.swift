//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// A Core Data managed object that stores one reusable rate template.
@objc(RateTemplate)
public final class RateTemplate: NSManagedObject {
    /// Validates insert operations before Core Data persists the object.
    ///
    /// - Throws: A validation error when the object violates business rules.
    override public func validateForInsert() throws {
        try super.validateForInsert()
        try RateTemplateManager.validateTemplateForSave(self)
    }

    /// Validates update operations before Core Data persists the object.
    ///
    /// - Throws: A validation error when the object violates business rules.
    override public func validateForUpdate() throws {
        try super.validateForUpdate()
        try RateTemplateManager.validateTemplateForSave(self)
    }
}
