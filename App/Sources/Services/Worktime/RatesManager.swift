//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// Applies normalization and validation rules for `Rates`.
public enum RatesManager {
    /// Validates one rate before save.
    ///
    /// - Parameter rate: The rate to validate.
    /// - Throws: `ValidationError` when one invariant is violated.
    public static func validateForSave(_ rate: Rates) throws {
        guard let billingType = BillingType(coreDataValue: rate.billing_type) else {
            throw ValidationError.rateMissingBillingType
        }

        switch billingType {
        case .hourly:
            guard let value = rate.hourly_rate?.doubleValue, value > 0 else {
                throw ValidationError.hourlyRateMissingValue
            }
        case .fixed:
            guard let value = rate.fixed_amount?.doubleValue, value > 0 else {
                throw ValidationError.fixedRateMissingValue
            }
        case .none:
            if (rate.hourly_rate?.doubleValue ?? 0) != 0 || (rate.fixed_amount?.doubleValue ?? 0) != 0 {
                throw ValidationError.noneRateHasValues
            }
        }

        if let validFrom = rate.valid_from, let validTo = rate.valid_to, validTo < validFrom {
            throw ValidationError.invalidValidityRange
        }
    }

    /// Normalizes one rate before save.
    ///
    /// - Parameter rate: The rate to normalize.
    public static func normalizeForSave(_ rate: Rates) {
        if rate.created_at == nil {
            rate.created_at = Date()
        }
        rate.updated_at = Date()

        if rate.is_default == nil {
            rate.is_default = NSNumber(value: false)
        }

        if let billingType = BillingType(coreDataValue: rate.billing_type) {
            switch billingType {
            case .hourly:
                rate.fixed_amount = nil
            case .fixed:
                rate.hourly_rate = nil
            case .none:
                rate.hourly_rate = nil
                rate.fixed_amount = nil
            }
        }
    }

    /// Normalizes, validates, and saves one rate.
    ///
    /// - Parameters:
    ///   - rate: The rate to persist.
    ///   - context: The managed object context to save.
    /// - Throws: `ValidationError` or Core Data save errors.
    public static func save(
        _ rate: Rates,
        in context: NSManagedObjectContext
    ) throws {
        normalizeForSave(rate)
        try validateForSave(rate)
        if context.hasChanges {
            try context.save()
        }
    }
}
