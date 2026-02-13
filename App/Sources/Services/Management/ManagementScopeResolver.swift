//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// Resolves profile-scoped visibility rules for master-data entities.
@MainActor
public enum ManagementScopeResolver {
    /// Resolves the currently selected profile from persisted settings.
    ///
    /// - Parameter context: The managed object context used for object resolution.
    /// - Returns: The selected profile or `nil` when no profile is active.
    public static func selectedProfile(in context: NSManagedObjectContext) -> Profile? {
        let profileURIString = SettingsStorageService.shared.activeProfileObjectURI
        guard profileURIString.isEmpty == false,
              let uri = URL(string: profileURIString),
              let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri),
              let object = try? context.existingObject(with: objectID),
              let profile = object as? Profile
        else {
            return nil
        }
        return profile
    }

    /// Evaluates one visibility rule for profile-scoped entities.
    ///
    /// - Parameters:
    ///   - entityProfile: The optional profile directly linked to the entity.
    ///   - sharedProfileFlag: The optional shared-profile flag.
    ///   - selectedProfile: The currently selected profile.
    /// - Returns: `true` when the entity is visible in the current scope.
    public static func isVisible(
        entityProfile: Profile?,
        sharedProfileFlag: NSNumber?,
        selectedProfile: Profile?
    ) -> Bool {
        guard let selectedProfile else {
            return true
        }

        let belongsToProfile = entityProfile?.objectID == selectedProfile.objectID
        let isShared = sharedProfileFlag?.boolValue ?? true
        return belongsToProfile || isShared
    }
}
