//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// Provides typed configuration access with profile-aware fallback resolution.
public struct ConfigurationStore {
    /// The context used for fetch and write operations.
    public let context: NSManagedObjectContext

    /// The active profile scope for reads.
    public let profile: Profile?

    /// Creates one configuration store.
    ///
    /// - Parameters:
    ///   - context: The managed object context.
    ///   - profile: The optional profile scope.
    public init(context: NSManagedObjectContext, profile: Profile? = nil) {
        self.context = context
        self.profile = profile
    }

    /// Resolves one string value with fallback order profile -> global -> default.
    ///
    /// - Parameters:
    ///   - key: The configuration key to resolve.
    ///   - defaultValue: The fallback value when no stored entry exists.
    /// - Returns: The resolved string value.
    /// - Throws: Any fetch error from Core Data.
    public func string(_ key: ConfigurationKey, default defaultValue: String? = nil) throws -> String? {
        if let value = try fetchValue(for: key.rawValue, profile: profile) { return value }
        if let value = try fetchValue(for: key.rawValue, profile: nil) { return value }
        return defaultValue
    }

    /// Resolves one boolean value with fallback.
    ///
    /// - Parameters:
    ///   - key: The configuration key to resolve.
    ///   - defaultValue: The fallback boolean.
    /// - Returns: The parsed boolean value.
    /// - Throws: Any fetch error from Core Data.
    public func bool(_ key: ConfigurationKey, default defaultValue: Bool = false) throws -> Bool {
        let raw = try string(key)
        guard let raw else { return defaultValue }
        return parseBool(raw) ?? defaultValue
    }

    /// Resolves one integer value with fallback.
    ///
    /// - Parameters:
    ///   - key: The configuration key to resolve.
    ///   - defaultValue: The fallback integer.
    /// - Returns: The parsed integer value.
    /// - Throws: Any fetch error from Core Data.
    public func int(_ key: ConfigurationKey, default defaultValue: Int = 0) throws -> Int {
        let raw = try string(key)
        guard let raw, let value = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)) else { return defaultValue }
        return value
    }

    /// Resolves one double value with fallback.
    ///
    /// - Parameters:
    ///   - key: The configuration key to resolve.
    ///   - defaultValue: The fallback double.
    /// - Returns: The parsed double value.
    /// - Throws: Any fetch error from Core Data.
    public func double(_ key: ConfigurationKey, default defaultValue: Double = 0) throws -> Double {
        let raw = try string(key)
        guard let raw else { return defaultValue }
        return parseDouble(raw) ?? defaultValue
    }

    /// Resolves one enum value with fallback.
    ///
    /// - Parameters:
    ///   - key: The configuration key to resolve.
    ///   - type: The enum type to decode.
    ///   - defaultValue: The fallback enum value.
    /// - Returns: The resolved enum value.
    /// - Throws: Any fetch error from Core Data.
    public func enumValue<T: CoreDataStringEnum>(
        _ key: ConfigurationKey,
        as _: T.Type,
        default defaultValue: T
    ) throws -> T {
        let raw = try string(key)
        return T(coreDataValue: raw) ?? defaultValue
    }

    /// Upserts one configuration value for one key and scope.
    ///
    /// - Parameters:
    ///   - key: The key to store.
    ///   - value: The string value to store.
    ///   - profile: The optional profile scope.
    /// - Throws: Any fetch error from Core Data.
    public func set(_ key: ConfigurationKey, value: String?, for profile: Profile? = nil) throws {
        let object = try fetchOrCreate(key: key.rawValue, profile: profile)
        object.config_value = value
        object.updated_at = Date()
        if object.created_at == nil { object.created_at = Date() }
    }
}

private extension ConfigurationStore {
    /// Fetches one raw configuration value for one key and scope.
    ///
    /// - Parameters:
    ///   - key: The raw key string.
    ///   - profile: The optional profile scope.
    /// - Returns: The value if found.
    /// - Throws: Any fetch error from Core Data.
    func fetchValue(for key: String, profile: Profile?) throws -> String? {
        let request = Configuration.fetchRequest()
        request.fetchLimit = 1

        if let profile {
            request.predicate = NSPredicate(format: "config_key == %@ AND profile == %@", key, profile)
        } else {
            request.predicate = NSPredicate(format: "config_key == %@ AND profile == nil", key)
        }

        return try context.fetch(request).first?.config_value
    }

    /// Fetches one existing configuration object or creates one new object.
    ///
    /// - Parameters:
    ///   - key: The raw key string.
    ///   - profile: The optional profile scope.
    /// - Returns: The existing or newly created configuration object.
    /// - Throws: Any fetch error from Core Data.
    func fetchOrCreate(key: String, profile: Profile?) throws -> Configuration {
        let request = Configuration.fetchRequest()
        request.fetchLimit = 1

        if let profile {
            request.predicate = NSPredicate(format: "config_key == %@ AND profile == %@", key, profile)
        } else {
            request.predicate = NSPredicate(format: "config_key == %@ AND profile == nil", key)
        }

        if let existing = try context.fetch(request).first {
            return existing
        }

        let created = Configuration(context: context)
        created.config_key = key
        created.profile = profile
        created.created_at = Date()
        created.updated_at = Date()
        return created
    }

    /// Parses one flexible boolean representation.
    ///
    /// - Parameter string: The raw value string.
    /// - Returns: The parsed boolean value or `nil`.
    func parseBool(_ string: String) -> Bool? {
        let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "1", "true", "yes", "y", "on": return true
        case "0", "false", "no", "n", "off": return false
        default: return nil
        }
    }

    /// Parses one double value, including comma decimal separators.
    ///
    /// - Parameter string: The raw value string.
    /// - Returns: The parsed double value or `nil`.
    func parseDouble(_ string: String) -> Double? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Double(trimmed) { return value }
        let replaced = trimmed.replacingOccurrences(of: ",", with: ".")
        return Double(replaced)
    }
}

/// Bundles resolved invoice defaults from configuration.
public struct InvoiceDefaults: Sendable {
    /// The default currency code.
    public let currency: String

    /// The default compliance jurisdiction.
    public let jurisdiction: Jurisdiction

    /// The default tax mode.
    public let taxMode: TaxMode

    /// The default payment terms.
    public let paymentTerms: PaymentTerms

    /// The default tax rate value.
    public let defaultTaxRate: Double

    /// Resolves invoice defaults from configuration values with static fallbacks.
    ///
    /// - Parameter store: The configuration store instance.
    /// - Returns: One resolved defaults object.
    /// - Throws: Any fetch error from Core Data.
    public static func resolve(using store: ConfigurationStore) throws -> InvoiceDefaults {
        let jurisdiction = try store.enumValue(.defaultJurisdiction, as: Jurisdiction.self, default: .europeanUnion)
        let currencyFallback = defaultCurrency(for: jurisdiction)
        let currency = try store.string(.defaultCurrency, default: currencyFallback) ?? currencyFallback
        let taxMode = try store.enumValue(.defaultTaxMode, as: TaxMode.self, default: defaultTaxMode(for: jurisdiction))
        let paymentTerms = try store.enumValue(.defaultPaymentTerms, as: PaymentTerms.self, default: .net14)
        let defaultTaxRate = try store.double(.defaultTaxRate, default: defaultTaxRate(for: jurisdiction, taxMode: taxMode))

        return InvoiceDefaults(
            currency: currency,
            jurisdiction: jurisdiction,
            taxMode: taxMode,
            paymentTerms: paymentTerms,
            defaultTaxRate: defaultTaxRate
        )
    }
}

private extension InvoiceDefaults {
    /// Returns default currency for one jurisdiction.
    ///
    /// - Parameter jurisdiction: The jurisdiction scope.
    /// - Returns: One default currency code.
    static func defaultCurrency(for jurisdiction: Jurisdiction) -> String {
        if jurisdiction.isUS { return "USD" }
        switch jurisdiction {
        case .germany, .europeanUnion: return "EUR"
        case .unitedKingdom: return "GBP"
        default: return "EUR"
        }
    }

    /// Returns default tax mode for one jurisdiction.
    ///
    /// - Parameter jurisdiction: The jurisdiction scope.
    /// - Returns: One default tax mode.
    static func defaultTaxMode(for jurisdiction: Jurisdiction) -> TaxMode {
        if jurisdiction.isUS { return .net }
        return .net
    }

    /// Returns default tax rate for one jurisdiction and tax mode.
    ///
    /// - Parameters:
    ///   - jurisdiction: The jurisdiction scope.
    ///   - taxMode: The selected tax mode.
    /// - Returns: One default tax rate.
    static func defaultTaxRate(for jurisdiction: Jurisdiction, taxMode: TaxMode) -> Double {
        if taxMode.showsTaxLines == false { return 0.0 }
        switch jurisdiction {
        case .germany: return 0.19
        default: return 0.0
        }
    }
}

public extension Invoice {
    /// Applies defaults only to unset invoice properties.
    ///
    /// - Parameter defaults: The resolved invoice defaults.
    func applyDefaults(_ defaults: InvoiceDefaults) {
        if currency == nil { currency = defaults.currency }
        if status == nil { status = InvoiceStatus.draft.coreDataValue }
        if issue_date == nil { issue_date = Date() }
        if tax_mode == nil { tax_mode = defaults.taxMode.coreDataValue }
        if jurisdiction == nil { jurisdiction = defaults.jurisdiction.coreDataValue }
        if payment_terms == nil { payment_terms = defaults.paymentTerms.coreDataValue }

        if due_date == nil,
           let days = defaults.paymentTerms.defaultDays,
           let issueDate = issue_date
        {
            due_date = Calendar.current.date(byAdding: .day, value: days, to: issueDate)
        }
    }
}
