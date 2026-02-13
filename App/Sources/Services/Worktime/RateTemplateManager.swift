//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// Applies validation and copy logic for reusable rate templates.
public enum RateTemplateManager {
    /// Validates one template before save.
    ///
    /// - Parameter template: The template to validate.
    /// - Throws: `ValidationError` when one invariant is violated.
    public static func validateTemplateForSave(_ template: RateTemplate) throws {
        guard let billingType = BillingType(coreDataValue: template.billing_type) else {
            throw ValidationError.rateMissingBillingType
        }

        switch billingType {
        case .hourly:
            guard let value = template.hourly_rate?.doubleValue, value > 0 else {
                throw ValidationError.hourlyRateMissingValue
            }
        case .fixed:
            guard let value = template.fixed_amount?.doubleValue, value > 0 else {
                throw ValidationError.fixedRateMissingValue
            }
        case .none:
            if (template.hourly_rate?.doubleValue ?? 0) != 0 || (template.fixed_amount?.doubleValue ?? 0) != 0 {
                throw ValidationError.noneRateHasValues
            }
        }

        if let validFrom = template.valid_from, let validTo = template.valid_to, validTo < validFrom {
            throw ValidationError.invalidValidityRange
        }
    }

    /// Normalizes one template before save.
    ///
    /// - Parameter template: The template to normalize.
    public static func normalizeForSave(_ template: RateTemplate) {
        if template.created_at == nil {
            template.created_at = Date()
        }
        template.updated_at = Date()

        if template.is_active == nil {
            template.is_active = NSNumber(value: true)
        }
        if template.shared_profile == nil {
            template.shared_profile = NSNumber(value: true)
        }

        let normalizedName = template.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        template.name = normalizedName.isEmpty ? nil : normalizedName

        if let billingType = BillingType(coreDataValue: template.billing_type) {
            switch billingType {
            case .hourly:
                template.fixed_amount = nil
            case .fixed:
                template.hourly_rate = nil
            case .none:
                template.hourly_rate = nil
                template.fixed_amount = nil
            }
        }
    }

    /// Normalizes, validates, and saves one rate template.
    ///
    /// - Parameters:
    ///   - template: The template that should be saved.
    ///   - context: The managed object context.
    /// - Throws: Validation or persistence errors.
    public static func saveTemplate(_ template: RateTemplate, in context: NSManagedObjectContext) throws {
        normalizeForSave(template)
        try validateTemplateForSave(template)
        if context.hasChanges {
            try context.save()
        }
    }

    /// Creates one new order-linked `Rates` instance by copying one template.
    ///
    /// - Parameters:
    ///   - template: The selected template.
    ///   - order: The destination order.
    ///   - context: The managed object context.
    /// - Returns: The created independent rate entity.
    /// - Throws: Validation or persistence errors.
    @discardableResult
    public static func applyTemplate(
        _ template: RateTemplate,
        to order: Order,
        in context: NSManagedObjectContext
    ) throws -> Rates {
        let createdRate = Rates.insert(into: context)
        let now = Date()
        createdRate.order = order
        createdRate.profile = order.profile ?? template.profile
        createdRate.activity = template.activity
        createdRate.name = template.name
        createdRate.billing_type = template.billing_type
        createdRate.hourly_rate = template.hourly_rate
        createdRate.fixed_amount = template.fixed_amount
        createdRate.valid_from = template.valid_from
        createdRate.valid_to = template.valid_to
        createdRate.shared_profile = NSNumber(value: false)
        createdRate.is_default = NSNumber(value: false)
        createdRate.created_at = now
        createdRate.updated_at = now
        createdRate.currency = try resolvedCurrency(for: template, order: order, context: context)

        try RatesManager.save(createdRate, in: context)
        return createdRate
    }
}

private extension RateTemplateManager {
    /// Resolves the currency to assign to a newly created rate.
    ///
    /// - Parameters:
    ///   - template: The selected template.
    ///   - order: The destination order.
    ///   - context: The managed object context.
    /// - Returns: One resolved currency code.
    /// - Throws: Configuration lookup errors.
    static func resolvedCurrency(
        for template: RateTemplate,
        order: Order,
        context: NSManagedObjectContext
    ) throws -> String {
        let trimmedTemplateCurrency = template.currency?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmedTemplateCurrency.isEmpty == false {
            return trimmedTemplateCurrency
        }

        let store = ConfigurationStore(context: context, profile: order.profile)
        let defaults = try InvoiceDefaults.resolve(using: store)
        return defaults.currency
    }
}
