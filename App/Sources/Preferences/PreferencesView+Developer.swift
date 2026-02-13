//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if os(macOS) && DEBUG
import CoreData
import SwiftUI

extension PreferencesView {
    /// The developer tools view available only in debug builds.
    var developerView: some View {
        DeveloperToolsView(
            preferences: preferences,
            appLanguageOverrideCode: $appLanguageOverrideCode,
            managedObjectContext: viewContext
        )
    }
}

/// Renders debug-only developer actions for settings and storage.
@MainActor
private struct DeveloperToolsView: View {
    /// The shared preferences model instance.
    let preferences: PreferencesModel

    /// The bound app language override code.
    @Binding var appLanguageOverrideCode: String

    /// The managed object context used for database operations.
    let managedObjectContext: NSManagedObjectContext

    /// Controls presentation of the clear-database confirmation alert.
    @State private var showsClearDatabaseConfirmation = false

    /// Controls presentation of the factory-reset confirmation alert.
    @State private var showsFactoryResetConfirmation = false

    /// Renders the developer tools body.
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacingM) {
                Text(L10n.generalMoreSectionDeveloper)
                    .textStyle(.title3)
                    .foregroundStyle(Color.aPrimary)

                VStack(alignment: .leading, spacing: .spacingS) {
                    Button(L10n.generalDeveloperResetDefaults) {
                        Task {
                            await resetAllSettingsToDefaults()
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button(L10n.settingsDeveloperSeedData) {
                        do {
                            _ = try DeveloperDatabaseSeedService.seedLast60Days(into: managedObjectContext)
                        } catch {
                            managedObjectContext.rollback()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button(L10n.settingsDeveloperClearDatabase) {
                        showsClearDatabaseConfirmation = true
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button(L10n.settingsDeveloperFactoryReset) {
                        showsFactoryResetConfirmation = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: .cornerRadius)
                        .fill(Color.aListBackground)
                )
            }
            .padding()
        }
        .alert(
            L10n.settingsDeveloperClearDatabaseTitle,
            isPresented: $showsClearDatabaseConfirmation
        ) {
            Button(L10n.generalCancel, role: .cancel) {}
            Button(L10n.settingsDeveloperClearDatabaseConfirm, role: .destructive) {
                clearDatabase()
            }
        } message: {
            Text("Datenbank leeren")
        }
        .alert(
            L10n.settingsDeveloperFactoryResetTitle,
            isPresented: $showsFactoryResetConfirmation
        ) {
            Button(L10n.generalCancel, role: .cancel) {}
            Button(L10n.settingsDeveloperFactoryResetConfirm, role: .destructive) {
                factoryResetAndExit()
            }
        } message: {
            Text(L10n.settingsDeveloperFactoryResetMessage)
        }
    }

    /// Resets all shared settings and language overrides to defaults.
    private func resetAllSettingsToDefaults() async {
        let settingsStorage = SettingsStorageService.shared
        settingsStorage.appearanceSelection = 0
        settingsStorage.isImpactEnabled = true
        settingsStorage.reportingSelectedTabIndex = 1
        settingsStorage.sharedDateRangePreset = .all
        settingsStorage.sharedDateRangeFrom = nil
        settingsStorage.sharedDateRangeTo = nil

        preferences.resetToDefaults()
        preferences.clearStorage()

        // Remove app-language overrides and use system language again.
        appLanguageOverrideCode = "system"
        UserDefaults.standard.removeObject(forKey: "appLanguageOverrideCode")
        UserDefaults.standard.removeObject(forKey: "AppleLanguages")

        await LocalPeerSyncCoordinator.shared?.forgetAllPeerSyncData()
    }

    /// Deletes all Core Data records from every entity in the current store.
    private func clearDatabase() {
        let entityNames = managedObjectContext.persistentStoreCoordinator?
            .managedObjectModel
            .entities
            .compactMap(\.name) ?? []

        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs

            do {
                let result = try managedObjectContext.execute(deleteRequest) as? NSBatchDeleteResult
                if let objectIDs = result?.result as? [NSManagedObjectID], objectIDs.isEmpty == false {
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                        into: [managedObjectContext]
                    )
                }
            } catch {
                continue
            }
        }
    }

    /// Deletes persistent store files and terminates the app process.
    private func factoryResetAndExit() {
        DeveloperDatabaseResetService.resetStoreAndExit(managedObjectContext: managedObjectContext)
    }
}
#endif
