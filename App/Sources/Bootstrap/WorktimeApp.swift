//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import CoreDataKit
import SwiftUI

#if os(iOS)
/// The main entry point of the WorktimeApp application.
@main
struct WorktimeApp: App {
    /// The app delegate responsible for handling application-level events.
    @UIApplicationDelegateAdaptor var delegate: AppDelegate

    /// The stored appearance selection used for theme overrides.
    @AppStorage(StorageKey.appearanceSelection) private var appearanceSelection: Int = 0

    /// Storage keys used by UserDefaults.
    private enum StorageKey {
        /// The appearance selection key.
        static let appearanceSelection = "UseDarkmode"
    }

    /// Holds one external CSV/TXT import file pending presentation.
    @State private var pendingImportFile: PendingImportFile?

    var appearanceSwitch: ColorScheme? {
        if appearanceSelection == 1 {
            .light
        } else if appearanceSelection == 2 {
            .dark
        } else {
            .none
        }
    }

    // CoreData Stack
    let coreDataCloudStackManager: CoreDataManager = {
        let configurationProvider = CoreDataStoreConfigurationProvider()
        let isICloudEnabled = SettingsStorageService.shared.isICloudSyncEnabled
        let databaseName = configurationProvider.databaseName(isICloudEnabled: isICloudEnabled)
        let syncMode: CloudSyncMode = if isICloudEnabled {
            .container(
                containerID: configurationProvider.cloudContainerIdentifier,
                scope: .private
            )
        } else {
            .none
        }
        let manager = CoreDataManager(
            bundle: Bundle.main,
            nameModel: "Worktime",
            databaseName: databaseName,
            databaseStorage: LocalStoragePath.libraryDirectory(appending: "Private Documents"),
            iCloudSyncMode: syncMode
        )
        return manager
    }()

    // MARK: - Scene Lifecycle

    /// The current scene phase for the app.
    @Environment(\.scenePhase) private var scenePhase

    /// The body of the app's main scene.
    var body: some Scene {
        WindowGroup {
            Bootstrap()
                .appThemeColors()
                .preferredColorScheme(appearanceSwitch)
                .environment(\.managedObjectContext, coreDataCloudStackManager.persistentContainer.viewContext)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .sheet(item: $pendingImportFile) { importFile in
                    NavigationStack {
                        ImportCSVPreparingView(
                            context: coreDataCloudStackManager.persistentContainer.viewContext,
                            fileURL: importFile.url
                        )
                    }
                    .appThemeColors()
                }
                .task {
                    configureLocalPeerSyncIfNeeded()
                    let context = coreDataCloudStackManager.persistentContainer.viewContext
                    await EntitlementStore.shared.refresh(context: context)

                    // Seed global master data if none exists (for new installations)
                    do {
                        try SeedService.seedGlobalActivitiesIfNeeded(in: context)
                        try SeedService.seedGlobalCostCentresIfNeeded(in: context)
                    } catch {
                        print("Failed to seed global master data: \(error)")
                    }
                }
        }
        .onChange(of: scenePhase) { _, newScenePhase in
            // Handle changes in app's scene phase
            switch newScenePhase {
            case .active:
                // The scene is in the foreground and interactive.
                print("The scene is in the foreground and interactive.")
                Task {
                    let context = coreDataCloudStackManager.persistentContainer.viewContext
                    _ = await AppStoreReviewManager.requestIf(launches: 5)
                    await EntitlementStore.shared.refresh(context: context)
                }
            case .inactive:
                // The scene is in the foreground but should pause its work.
                print("The scene is in the foreground but should pause its work.")
            case .background:
                // The scene isn’t currently visible in the UI.
                print("The scene isn’t currently visible in the UI.")
            @unknown default:
                break
            }
        }
    }

    /// Handles incoming URLs and dispatches backup or CSV import flows.
    ///
    /// - Parameter url: The incoming URL from Files/Share Sheet.
    private func handleIncomingURL(_ url: URL) {
        let fileExtension = url.pathExtension.lowercased()

        if fileExtension == "csv" || fileExtension == "txt" {
            pendingImportFile = PendingImportFile(url: url)
        }
    }

    /// Configures local peer sync once per process without starting network hosting.
    private func configureLocalPeerSyncIfNeeded() {
        if LocalPeerSyncCoordinator.shared == nil {
            LocalPeerSyncCoordinator.configureShared(container: coreDataCloudStackManager.persistentContainer)
        }
    }
}

/// Stores one pending external import file used for sheet presentation.
private struct PendingImportFile: Identifiable {
    /// Stable sheet identity.
    let id = UUID()

    /// The source file URL to import.
    let url: URL
}
#endif
