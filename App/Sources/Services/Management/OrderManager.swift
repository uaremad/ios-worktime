//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// Provides write operations and validation for `Order` entities.
@MainActor
public enum OrderManager {
    /// Saves one order with domain validation.
    ///
    /// - Parameters:
    ///   - order: The order to validate and save.
    ///   - context: The managed object context used for persistence.
    /// - Throws: Validation or persistence errors.
    public static func save(_ order: Order, in context: NSManagedObjectContext) throws {
        let normalizedName = order.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let normalizedCode = order.code?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard normalizedName.isEmpty == false || normalizedCode.isEmpty == false else {
            throw ValidationError.orderNameOrCodeRequired
        }

        if let validFrom = order.valid_from, let validTo = order.valid_to, validTo < validFrom {
            throw ValidationError.invalidValidityRange
        }

        order.name = normalizedName.isEmpty ? nil : normalizedName
        order.code = normalizedCode.isEmpty ? nil : normalizedCode

        if order.created_at == nil {
            order.created_at = Date()
        }
        order.updated_at = Date()

        if context.hasChanges {
            try context.save()
        }
    }
}
