//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI
#if canImport(Darwin)
import Darwin
#endif
#if os(macOS)
import AppKit
#endif

/// Manages state and actions for the More menu screen.
@MainActor
@Observable
final class MoreMenuViewModel {
    /// The supported appearance options for iOS theme selection.
    enum AppearanceOption: Int, CaseIterable, Identifiable {
        /// Follows the system appearance.
        case automatic = 0
        /// Forces light appearance.
        case light = 1
        /// Forces dark appearance.
        case dark = 2

        /// The stable identifier used for list rendering.
        var id: Int { rawValue }

        /// The localized label displayed to users.
        var localizedTitle: String {
            switch self {
            case .automatic:
                L10n.generalMoreAppearanceAutomatic
            case .light:
                L10n.generalMoreAppearanceLight
            case .dark:
                L10n.generalMoreAppearanceDark
            }
        }

        /// The SF Symbol that represents the option.
        var symbolName: String {
            switch self {
            case .automatic:
                "circle.lefthalf.filled"
            case .light:
                "sun.max.fill"
            case .dark:
                "moon.fill"
            }
        }
    }

    /// UserDefaults keys used by developer actions.
    enum StorageKey {
        /// Indicates whether the legacy bootstrap privacy flow was shown.
        static let privacyPolicyWasShown = "privacyPolicyWasShown"
        /// Indicates whether the first-start purchases modal was shown.
        static let firstStartPurchasesWasShown = "firstStartPurchasesWasShown"
        /// Stores the selected appearance mode for iOS.
        static let appearanceSelection = "UseDarkmode"
    }

    /// Controls presentation of the reset confirmation alert.
    var showsResetConfirmationAlert: Bool = false
    /// The exported backup file URL used by share presentation.
    var exportFileURL: URL?
    /// Indicates whether export error alert is presented.
    var showsExportErrorAlert: Bool = false
    /// Stores the latest export error message.
    var exportErrorMessage: String = ""
    #if os(iOS)
    /// Controls presentation of the appearance picker sheet.
    var showsAppearanceSheet: Bool = false
    /// Provides access to the shared impact manager as source of truth.
    @ObservationIgnored
    private let impactManager: ImpactManager = .shared

    /// Controls whether haptic feedback is enabled for supported interactions.
    ///
    /// This setting is stored and read directly from `ImpactManager.shared`.
    var isHapticFeedbackEnabled: Bool {
        get { impactManager.isImpactEnabled }
        set { impactManager.setImpactEnabled(newValue) }
    }

    /// The persisted appearance selection used by the app root.
    var appearanceSelection: Int {
        didSet {
            userDefaults.set(appearanceSelection, forKey: StorageKey.appearanceSelection)
        }
    }

    #endif

    /// The UserDefaults store used for persisted settings.
    private let userDefaults: UserDefaults
    /// Creates a new view model instance.
    init(
        userDefaults: UserDefaults = .standard
    ) {
        self.userDefaults = userDefaults
        #if os(iOS)
        appearanceSelection = userDefaults.integer(forKey: StorageKey.appearanceSelection)
        #endif
    }

    /// Resets all persisted defaults and terminates the app process.
    func resetAllDefaultsAndExit() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            userDefaults.removePersistentDomain(forName: bundleIdentifier)
        }
        #if os(iOS)
        PurchaseStorageService.shared.reset()
        #endif
        userDefaults.set(false, forKey: StorageKey.privacyPolicyWasShown)
        userDefaults.set(false, forKey: StorageKey.firstStartPurchasesWasShown)
        userDefaults.synchronize()
        exit(0)
    }

    /// Resets persisted defaults, clears all local database entities, and reseeds default master data.
    ///
    /// - Important: This action keeps the app running and rebuilds baseline master data.
    /// - Parameter context: The managed object context used for database cleanup and reseeding.
    func resetDefaultsAndReseedCostCentres(context: NSManagedObjectContext) {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            userDefaults.removePersistentDomain(forName: bundleIdentifier)
        }
        #if os(iOS)
        PurchaseStorageService.shared.reset()
        #endif
        userDefaults.set(false, forKey: StorageKey.privacyPolicyWasShown)
        userDefaults.set(false, forKey: StorageKey.firstStartPurchasesWasShown)
        userDefaults.synchronize()

        clearAllEntities(in: context)

        do {
            try SeedService.seedGlobalActivitiesIfNeeded(in: context)
            try SeedService.seedGlobalCostCentresIfNeeded(in: context)
        } catch {
            print("Failed to reseed global master data after reset: \(error)")
        }
    }

    /// Deletes all records from all entities of the current Core Data model.
    ///
    /// - Parameter context: The managed object context used for batch deletion.
    private func clearAllEntities(in context: NSManagedObjectContext) {
        let entityNames = context.persistentStoreCoordinator?
            .managedObjectModel
            .entities
            .compactMap(\.name) ?? []

        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs

            do {
                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                if let objectIDs = result?.result as? [NSManagedObjectID], objectIDs.isEmpty == false {
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                        into: [context]
                    )
                }
            } catch {
                print("Failed to clear entity \(entityName): \(error)")
            }
        }
        context.reset()
    }

    /// The platform-specific transfer button title.
    var transferButtonTitle: String {
        #if os(iOS)
        return L10n.generalMoreTransferToMac
        #else
        return L10n.generalMoreTransferToIos
        #endif
    }

    #if os(macOS)
    /// Presents `NSSharingServicePicker` for the exported backup file.
    ///
    /// - Parameter fileURL: The backup file URL to share.
    func presentMacSharingPicker(for fileURL: URL) {
        guard let contentView = NSApp.keyWindow?.contentView else {
            exportErrorMessage = L10n.errorBackupExportMessage
            showsExportErrorAlert = true
            return
        }

        let picker = NSSharingServicePicker(items: [fileURL])
        picker.show(
            relativeTo: NSRect(
                x: contentView.bounds.midX,
                y: contentView.bounds.midY,
                width: 1,
                height: 1
            ),
            of: contentView,
            preferredEdge: .minY
        )
    }
    #endif

    #if os(iOS)
    /// The currently selected appearance option resolved from persisted storage.
    var selectedAppearanceOption: AppearanceOption {
        AppearanceOption(rawValue: appearanceSelection) ?? .automatic
    }
    #endif
}
