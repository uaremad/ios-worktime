//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// Provides write operations for `Client` entities.
@MainActor
public enum ClientManager {
    /// Creates one client quickly from a single name input.
    ///
    /// - Parameters:
    ///   - name: The user-entered client name.
    ///   - context: The managed object context used for persistence.
    /// - Returns: The newly created client.
    /// - Throws: Validation or Core Data save errors.
    @discardableResult
    public static func createQuick(name: String, in context: NSManagedObjectContext) throws -> Client {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedName.isEmpty == false else {
            throw ValidationError.clientNameRequired
        }

        let client = Client.insert(into: context)
        let now = Date()
        client.name = normalizedName
        client.is_active = NSNumber(value: true)
        client.shared_profile = NSNumber(value: true)
        client.created_at = now
        client.updated_at = now
        client.profile = ManagementScopeResolver.selectedProfile(in: context)

        if context.hasChanges {
            try context.save()
        }
        return client
    }

    /// Saves one client with full edit fields.
    ///
    /// - Parameters:
    ///   - client: The client to save.
    ///   - context: The managed object context used for persistence.
    /// - Throws: Validation or Core Data save errors.
    public static func save(_ client: Client, in context: NSManagedObjectContext) throws {
        let normalizedName = client.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard normalizedName.isEmpty == false else {
            throw ValidationError.clientNameRequired
        }
        client.name = normalizedName
        if client.created_at == nil {
            client.created_at = Date()
        }
        client.updated_at = Date()

        if context.hasChanges {
            try context.save()
        }
    }
}
