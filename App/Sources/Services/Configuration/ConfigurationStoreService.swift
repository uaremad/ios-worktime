//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import CoreDataKit
import Foundation

/// Provides read and write access for dynamic key-value configuration entries.
@MainActor
public final class ConfigurationStoreService {
    /// Shared singleton instance for app-wide usage.
    public static let shared = ConfigurationStoreService()

    /// Default singular label if no configuration value exists.
    public let defaultCounterpartyLabelSingular = "Kunde"

    /// Default plural label if no configuration value exists.
    public let defaultCounterpartyLabelPlural = "Kunden"

    /// Creates a new configuration service instance.
    public init() {}

    /// Resolves a configuration value using profile scope fallback.
    ///
    /// Lookup order:
    /// 1) Profile-specific value (`profile != nil`)
    /// 2) Global value (`profile == nil`)
    /// 3) `nil` when no value exists
    ///
    /// - Parameters:
    ///   - key: The configuration key to resolve.
    ///   - profile: Optional profile scope.
    ///   - context: The managed object context used for fetching.
    /// - Returns: The resolved value if available.
    /// - Throws: Any fetch error from Core Data.
    public func value(
        for key: ConfigurationKey,
        profile: Profile?,
        context: NSManagedObjectContext
    ) throws -> String? {
        if let profile,
           let scopedEntry = try fetchConfiguration(for: key, profile: profile, context: context),
           let scopedValue = normalizedValue(scopedEntry.config_value)
        {
            return scopedValue
        }

        if let globalEntry = try fetchConfiguration(for: key, profile: nil, context: context),
           let globalValue = normalizedValue(globalEntry.config_value)
        {
            return globalValue
        }

        return nil
    }

    /// Upserts a configuration value for a given key and scope.
    ///
    /// Passing an empty or whitespace value removes an existing entry for the scope.
    ///
    /// - Parameters:
    ///   - value: The value to persist.
    ///   - key: The configuration key to write.
    ///   - profile: Optional profile scope.
    ///   - context: The managed object context used for persistence.
    /// - Throws: Any Core Data fetch or save error.
    public func setValue(
        _ value: String?,
        for key: ConfigurationKey,
        profile: Profile?,
        context: NSManagedObjectContext
    ) throws {
        let existingEntries = try fetchConfigurations(for: key, profile: profile, context: context)
        let existing = existingEntries.first
        let normalized = normalizedValue(value)

        guard let normalized else {
            if existingEntries.isEmpty == false {
                for entry in existingEntries {
                    context.delete(entry)
                }
                try context.saveIfNeeded()
            }
            return
        }

        let entry = existing ?? Configuration(context: context)
        entry.config_key = key.rawValue
        entry.config_value = normalized
        entry.profile = profile
        if entry.created_at == nil {
            entry.created_at = Date()
        }
        entry.updated_at = Date()

        // App-side uniqueness enforcement for (config_key, profile).
        for duplicate in existingEntries.dropFirst() {
            context.delete(duplicate)
        }
        try context.saveIfNeeded()
    }

    /// Resolves the singular counterparty label with fallback to the built-in default.
    ///
    /// - Parameters:
    ///   - profile: Optional profile scope.
    ///   - context: The managed object context used for fetching.
    /// - Returns: A non-empty singular label.
    /// - Throws: Any fetch error from Core Data.
    public func counterpartyLabelSingular(
        profile: Profile?,
        context: NSManagedObjectContext
    ) throws -> String {
        try value(for: .counterpartyLabelSingular, profile: profile, context: context) ?? defaultCounterpartyLabelSingular
    }

    /// Resolves the plural counterparty label with fallback to the built-in default.
    ///
    /// - Parameters:
    ///   - profile: Optional profile scope.
    ///   - context: The managed object context used for fetching.
    /// - Returns: A non-empty plural label.
    /// - Throws: Any fetch error from Core Data.
    public func counterpartyLabelPlural(
        profile: Profile?,
        context: NSManagedObjectContext
    ) throws -> String {
        try value(for: .counterpartyLabelPlural, profile: profile, context: context) ?? defaultCounterpartyLabelPlural
    }
}

private extension ConfigurationStoreService {
    /// Fetches all configuration entries for one key and scope.
    ///
    /// - Parameters:
    ///   - key: The key to fetch.
    ///   - profile: Optional profile scope.
    ///   - context: The managed object context used for fetching.
    /// - Returns: Matching configuration entries sorted by latest update first.
    /// - Throws: Any fetch error from Core Data.
    func fetchConfigurations(
        for key: ConfigurationKey,
        profile: Profile?,
        context: NSManagedObjectContext
    ) throws -> [Configuration] {
        let request = Configuration.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "updated_at", ascending: false)]

        if let profile {
            request.predicate = NSPredicate(
                format: "config_key == %@ AND profile == %@",
                key.rawValue,
                profile
            )
        } else {
            request.predicate = NSPredicate(
                format: "config_key == %@ AND profile == nil",
                key.rawValue
            )
        }

        return try context.fetch(request)
    }

    /// Fetches one latest configuration entry for a key and scope.
    ///
    /// - Parameters:
    ///   - key: The key to fetch.
    ///   - profile: Optional profile scope.
    ///   - context: The managed object context used for fetching.
    /// - Returns: The latest matching configuration entry if present.
    /// - Throws: Any fetch error from Core Data.
    func fetchConfiguration(
        for key: ConfigurationKey,
        profile: Profile?,
        context: NSManagedObjectContext
    ) throws -> Configuration? {
        try fetchConfigurations(for: key, profile: profile, context: context).first
    }

    /// Trims and validates a raw value string.
    ///
    /// - Parameter value: The raw input value.
    /// - Returns: A non-empty trimmed string or `nil`.
    func normalizedValue(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
