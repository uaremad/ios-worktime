//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// Seed keys for default activities.
enum ActivitySeedKey: String, CaseIterable {
    case work = "activity.work"
    case `break` = "activity.break"
    case meeting = "activity.meeting"
    case travel = "activity.travel"
    case admin = "activity.admin"

    /// Localized name for the activity.
    var localizedName: String {
        switch self {
        case .work:
            L10n.activityWork
        case .break:
            L10n.activityBreak
        case .meeting:
            L10n.activityMeeting
        case .travel:
            L10n.activityTravel
        case .admin:
            L10n.activityAdmin
        }
    }
}

/// Seed keys for default cost centres.
enum CostCentreSeedKey: String, CaseIterable {
    /// Seed key for the default project allocation bucket.
    ///
    /// - Note: The raw value keeps the legacy identifier for compatibility.
    case project = "costcentre.general"
    case `internal` = "costcentre.internal"
    case admin = "costcentre.admin"

    /// Localized name for the cost centre.
    var localizedName: String {
        switch self {
        case .project:
            L10n.costCentreGeneral
        case .internal:
            L10n.costCentreInternal
        case .admin:
            L10n.costCentreAdmin
        }
    }
}

/// Manages seeding of default master data for profiles.
///
/// This service ensures that all profiles have standard activities and cost centres
/// available for immediate use. The seeded data uses seed keys for identification
/// and versioning, allowing for future updates to default data.
@MainActor
public enum SeedService {
    /// Seeds default activities globally if none exist.
    ///
    /// This method checks if any activities exist in the database. If none exist,
    /// it seeds one global baseline activity set without profile binding.
    ///
    /// - Parameter context: The managed object context.
    /// - Throws: Any Core Data persistence error.
    public static func seedGlobalActivitiesIfNeeded(in context: NSManagedObjectContext) throws {
        let request = Activities.fetchRequest()
        request.fetchLimit = 1
        let existingCount = try context.count(for: request)

        if existingCount == 0 {
            try seedGlobalActivities(in: context)
        }
    }

    /// Seeds default cost centres globally if none exist.
    ///
    /// This method checks if any cost centres exist in the database (from previous
    /// installations or iCloud sync). If none exist, it seeds the default global
    /// cost centres. This ensures that new installations get default data while
    /// existing installations with user data are not affected.
    ///
    /// - Parameter context: The managed object context.
    /// - Throws: Any Core Data persistence error.
    public static func seedGlobalCostCentresIfNeeded(in context: NSManagedObjectContext) throws {
        // Check if any cost centres already exist
        let request = CostCentre.fetchRequest()
        request.fetchLimit = 1
        let existingCount = try context.count(for: request)

        // Only seed if no cost centres exist at all
        if existingCount == 0 {
            try seedGlobalCostCentres(in: context)
        }
    }

    /// Seeds default activities and cost centres for all profiles that don't have them yet.
    ///
    /// This method should be called on app startup to ensure all existing profiles
    /// have the required default master data. It checks for existing seed data and
    /// only creates missing entries.
    ///
    /// - Parameter context: The managed object context.
    /// - Throws: Any Core Data persistence error.
    public static func seedAllProfiles(in context: NSManagedObjectContext) throws {
        let request = Profile.fetchRequest()
        request.predicate = NSPredicate(format: "(is_active == nil) OR (is_active == YES)")
        let profiles = try context.fetch(request)

        for profile in profiles {
            try seedDefaults(for: profile, in: context)
        }
    }

    /// Seeds default activities and cost centres for a new profile.
    ///
    /// This method should be called when a new profile is created to provide
    /// standard master data. It checks for existing seed data and only creates
    /// missing entries.
    ///
    /// - Parameters:
    ///   - profile: The profile to seed data for.
    ///   - context: The managed object context.
    /// - Throws: Any Core Data persistence error.
    public static func seedDefaults(for profile: Profile, in context: NSManagedObjectContext) throws {
        try seedActivities(for: profile, in: context)
        try seedCostCentres(for: profile, in: context)

        if context.hasChanges {
            try context.save()
        }
    }
}

private extension SeedService {
    /// Seeds global default activities.
    ///
    /// - Parameter context: The managed object context.
    /// - Throws: Any Core Data persistence error.
    static func seedGlobalActivities(in context: NSManagedObjectContext) throws {
        for seedKey in ActivitySeedKey.allCases {
            let activity = Activities.insert(into: context)
            activity.name = seedKey.localizedName
            activity.shared_profile = NSNumber(value: false)
            activity.is_active = NSNumber(value: true)
        }

        if context.hasChanges {
            try context.save()
        }
    }

    /// Seeds global default cost centres.
    ///
    /// - Parameter context: The managed object context.
    /// - Throws: Any Core Data persistence error.
    static func seedGlobalCostCentres(in context: NSManagedObjectContext) throws {
        for seedKey in CostCentreSeedKey.allCases {
            // Create new global cost centre
            let costCentre = CostCentre.insert(into: context)
            costCentre.name = seedKey.localizedName
            costCentre.shared_profile = NSNumber(value: false)
            // Note: No profile set for global cost centres
        }

        if context.hasChanges {
            try context.save()
        }
    }

    /// Seeds default activities for a profile.
    ///
    /// - Parameters:
    ///   - profile: The profile to seed activities for.
    ///   - context: The managed object context.
    /// - Throws: Any Core Data persistence error.
    static func seedActivities(
        for profile: Profile,
        in context: NSManagedObjectContext
    ) throws {
        for seedKey in ActivitySeedKey.allCases {
            // Check if activity already exists for this seed key
            let request = Activities.fetchRequest()
            request.predicate = NSPredicate(format: "profile == %@ AND name == %@", profile, seedKey.localizedName)
            request.fetchLimit = 1

            if try (context.fetch(request).first) != nil {
                // Activity already exists, skip
                continue
            }

            // Create new activity
            let activity = Activities.insert(into: context)
            activity.profile = profile
            activity.name = seedKey.localizedName
            activity.shared_profile = NSNumber(value: false)
        }
    }

    /// Seeds default cost centres for a profile.
    ///
    /// - Parameters:
    ///   - profile: The profile to seed cost centres for.
    ///   - context: The managed object context.
    /// - Throws: Any Core Data persistence error.
    static func seedCostCentres(
        for profile: Profile,
        in context: NSManagedObjectContext
    ) throws {
        for seedKey in CostCentreSeedKey.allCases {
            // Check if cost centre already exists for this profile
            let request = CostCentre.fetchRequest()
            request.predicate = NSPredicate(format: "profile == %@ AND name == %@", profile, seedKey.localizedName)
            request.fetchLimit = 1

            if try (context.fetch(request).first) != nil {
                // Cost centre already exists, skip
                continue
            }

            // Create new cost centre
            let costCentre = CostCentre.insert(into: context)
            costCentre.profile = profile
            costCentre.name = seedKey.localizedName
            costCentre.shared_profile = NSNumber(value: false)
        }
    }
}
