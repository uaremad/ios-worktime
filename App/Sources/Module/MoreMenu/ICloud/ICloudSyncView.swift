//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import CoreDataKit
import SwiftUI
#if canImport(CloudKit)
import CloudKit
#endif

/// Presents iCloud synchronization settings and status actions.
@MainActor
struct ICloudSyncView: View {
    /// Provides access to the current managed object context.
    @Environment(\.managedObjectContext) private var viewContext

    /// Tracks the toggle state for iCloud synchronization.
    @State private var isICloudSyncEnabled = false
    /// Prevents feedback loops while updating the toggle programmatically.
    @State private var isProgrammaticToggleUpdate = false
    /// Indicates whether a sync migration operation is currently running.
    @State private var isSyncInProgress = false
    /// Controls presentation of the iCloud availability error alert.
    @State private var showsICloudUnavailableAlert = false
    /// Controls presentation of the iCloud migration success alert.
    @State private var showsSuccessAlert = false
    /// Stores the success message shown after migration.
    @State private var successMessage = ""
    /// Handles store migration when toggling iCloud mode.
    @State private var migrationViewModel = ICloudSyncMigrationViewModel()

    /// Renders the iCloud settings screen.
    var body: some View {
        List {
            Section("Synchronisierung") {
                Toggle(isOn: $isICloudSyncEnabled) {
                    HStack(spacing: .spacingS) {
                        Image(systemName: isICloudSyncEnabled ? "icloud.fill" : "icloud")
                            .foregroundStyle(Color.accentColor)
                            .accessibilityHidden(true)
                        Text("iCloud Synchronisierung")
                            .textStyle(.body1)
                    }
                }
                .disabled(isSyncInProgress)

                Text("Synchronisiere Zeiteinträge und Tags über iCloud auf allen Geräten.")
                    .textStyle(.body3)
                    .foregroundStyle(Color.aPrimary.opacity(0.7))

                NavigationLink {
                    ICloudInfoView()
                } label: {
                    HStack(spacing: .spacingS) {
                        Text("iCloud Details")
                            .textStyle(.body1)
                        Spacer()
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .scrollContentBackground(.hidden)
        .background(Color.aBackground)
        .navigationTitle("iCloud")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .overlay {
                if isSyncInProgress {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding(.spacingM)
                        .background(Color.aListBackground)
                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius))
                }
            }
            .onAppear {
                syncToggleWithStoreState()
            }
            .onChange(of: isICloudSyncEnabled) { oldValue, newValue in
                guard isProgrammaticToggleUpdate == false else {
                    return
                }
                Task {
                    await applyCloudToggleChange(oldValue: oldValue, newValue: newValue)
                }
            }
            .alert("iCloud nicht verfügbar", isPresented: $showsICloudUnavailableAlert) {
                Button(L10n.generalOk, role: .cancel) {}
            } message: {
                Text("Bitte prüfe deine iCloud-Anmeldung und den iCloud-Status auf diesem Gerät.")
            }
            .alert("iCloud Synchronisierung", isPresented: $showsSuccessAlert) {
                Button(L10n.generalOk, role: .cancel) {}
            } message: {
                Text(successMessage)
            }
    }
}

private extension ICloudSyncView {
    /// Synchronizes the toggle and persisted setting with the active Core Data state.
    func syncToggleWithStoreState() {
        let actualState = CoreDataManager.isCloud
        isProgrammaticToggleUpdate = true
        isICloudSyncEnabled = actualState
        SettingsStorageService.shared.isICloudSyncEnabled = actualState
        Task { @MainActor in
            await Task.yield()
            isProgrammaticToggleUpdate = false
        }
    }

    /// Applies one iCloud toggle change including migration and store reload.
    ///
    /// - Parameters:
    ///   - oldValue: The previous toggle value.
    ///   - newValue: The new toggle value.
    func applyCloudToggleChange(oldValue: Bool, newValue: Bool) async {
        SettingsStorageService.shared.isICloudSyncEnabled = newValue
        isSyncInProgress = true
        defer { isSyncInProgress = false }

        if newValue, await isICloudAvailable() == false {
            isProgrammaticToggleUpdate = true
            isICloudSyncEnabled = oldValue
            SettingsStorageService.shared.isICloudSyncEnabled = oldValue
            await Task.yield()
            isProgrammaticToggleUpdate = false
            showsSuccessAlert = false
            showsICloudUnavailableAlert = true
            return
        }

        let migrationSucceeded = await migrationViewModel.synchronizeStores(
            oldSelection: oldValue,
            newSelection: newValue,
            context: viewContext
        )
        if migrationSucceeded {
            let provider = CoreDataStoreConfigurationProvider()
            let configuration = provider.storeConfiguration(isICloudEnabled: newValue)
            CoreDataManager.shared?.applyStoreConfiguration(configuration)
        }

        let actualState = CoreDataManager.isCloud
        SettingsStorageService.shared.isICloudSyncEnabled = actualState
        if actualState != newValue || migrationSucceeded == false {
            isProgrammaticToggleUpdate = true
            isICloudSyncEnabled = actualState
            await Task.yield()
            isProgrammaticToggleUpdate = false
            showsSuccessAlert = false
            showsICloudUnavailableAlert = true
            return
        }

        successMessage = actualState
            ? "iCloud-Synchronisierung wurde aktiviert."
            : "iCloud-Synchronisierung wurde deaktiviert."
        showsICloudUnavailableAlert = false
        showsSuccessAlert = true
    }

    /// Checks whether iCloud is available for the configured CloudKit container.
    ///
    /// - Returns: `true` when iCloud account access is available.
    func isICloudAvailable() async -> Bool {
        #if canImport(CloudKit)
        let containerId = AppInfo().cloudContainerId
        guard containerId.isEmpty == false else {
            return false
        }
        let container = CKContainer(identifier: containerId)
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            return false
        }
        #else
        return false
        #endif
    }
}
