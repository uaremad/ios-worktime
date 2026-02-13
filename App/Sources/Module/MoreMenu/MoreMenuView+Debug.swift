//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if DEBUG
import CoreData
import SwiftUI
#if canImport(StoreKit)
import StoreKit
#endif

extension MoreMenuView {
    /// Renders the debug-only developer section.
    @ViewBuilder
    var developerSection: some View {
        #if os(iOS)
        MoreMenuDebugDeveloperSection { managedObjectContext in
            viewModel.resetDefaultsAndReseedCostCentres(context: managedObjectContext)
        } onOpenOnboarding: {
            showsDeveloperOnboardingPreview = true
        }
        #else
        Section {
            Button {
                viewModel.showsResetConfirmationAlert = true
            } label: {
                HStack(spacing: .spacingS) {
                    Text(L10n.generalDeveloperResetDefaults)
                        .textStyle(.body1)
                    Spacer()
                    Image(systemName: "arrow.counterclockwise")
                        .symbolRenderingMode(.hierarchical)
                        .imageScale(.medium)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.generalDeveloperResetDefaults)
            .accessibilityAddTraits(.isButton)
        } header: {
            Text(L10n.generalMoreSectionDeveloper)
                .textStyle(.title3)
                .accessibilityAddTraits(.isHeader)
        }
        .listRowBackground(Color.aListBackground)
        .alert(L10n.generalDeveloperResetDefaultsTitle, isPresented: $viewModel.showsResetConfirmationAlert) {
            Button(L10n.generalCancel, role: .cancel) {}
            Button(L10n.generalDeveloperResetDefaultsConfirm, role: .destructive) {
                viewModel.resetAllDefaultsAndExit()
            }
        } message: {
            Text(L10n.generalDeveloperResetDefaultsMessage)
        }
        #endif
    }
}

#if os(iOS)
/// Renders iOS debug actions in the More menu.
@MainActor
private struct MoreMenuDebugDeveloperSection: View {
    /// The context used for debug data actions.
    @Environment(\.managedObjectContext) private var managedObjectContext

    /// Handles the reset-defaults destructive action.
    let onResetDefaults: (NSManagedObjectContext) -> Void

    /// Opens the onboarding preview from the developer section.
    let onOpenOnboarding: () -> Void

    /// Controls presentation of the reset confirmation alert.
    @State private var showsResetDefaultsConfirmation = false
    /// Controls presentation of the clear-database confirmation alert.
    @State private var showsClearDatabaseConfirmation = false
    /// Controls presentation of the factory-reset confirmation alert.
    @State private var showsFactoryResetConfirmation = false
    /// Controls presentation of the seed result alert.
    @State private var showsSeedResultAlert = false
    /// Controls presentation of the purchase metadata sheet.
    @State private var showsPurchaseMetadataSheet = false
    /// Stores loaded product metadata for the developer sheet.
    @State private var purchaseMetadataEntries: [PurchaseMetadataEntry] = []
    /// Indicates whether purchase metadata loading is currently active.
    @State private var isLoadingPurchaseMetadata = false
    /// Indicates that loading purchase metadata failed.
    @State private var didFailLoadingPurchaseMetadata = false
    /// Stores the number of records created by the latest seed operation.
    @State private var seededRecordCount = 0
    /// Renders the view body.
    var body: some View {
        developerSectionWithPresenters
    }

    /// The base developer section before alert and sheet modifiers are attached.
    private var developerSectionBody: some View {
        Section {
            Button {
                onOpenOnboarding()
            } label: {
                HStack(spacing: .spacingS) {
                    Text(L10n.generalDeveloperOnboarding)
                        .textStyle(.body1)
                    Spacer()
                    Image(systemName: "rectangle.on.rectangle")
                        .symbolRenderingMode(.hierarchical)
                        .imageScale(.medium)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.generalDeveloperOnboarding)
            .accessibilityAddTraits(.isButton)

            Button {
                showsPurchaseMetadataSheet = true
            } label: {
                HStack(spacing: .spacingS) {
                    Text(L10n.settingsMorePurchasesTitle)
                        .textStyle(.body1)
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .symbolRenderingMode(.hierarchical)
                        .imageScale(.medium)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.settingsMorePurchasesTitle)
            .accessibilityAddTraits(.isButton)

            Button {
                showsClearDatabaseConfirmation = true
            } label: {
                HStack(spacing: .spacingS) {
                    Text(L10n.settingsDeveloperClearDatabase)
                        .textStyle(.body1)
                    Spacer()
                    Image(systemName: "trash")
                        .symbolRenderingMode(.hierarchical)
                        .imageScale(.medium)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.settingsDeveloperClearDatabase)
            .accessibilityAddTraits(.isButton)

            Button {
                do {
                    seededRecordCount = try DeveloperDatabaseSeedService.seedLast60Days(into: managedObjectContext)
                } catch {
                    managedObjectContext.rollback()
                    seededRecordCount = 0
                }
                showsSeedResultAlert = true
            } label: {
                HStack(spacing: .spacingS) {
                    Text(L10n.settingsDeveloperSeedData)
                        .textStyle(.body1)
                    Spacer()
                    Image(systemName: "plus.circle")
                        .symbolRenderingMode(.hierarchical)
                        .imageScale(.medium)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.settingsDeveloperSeedData)
            .accessibilityAddTraits(.isButton)

            Button {
                showsResetDefaultsConfirmation = true
            } label: {
                HStack(spacing: .spacingS) {
                    Text(L10n.generalDeveloperResetDefaults)
                        .textStyle(.body1)
                    Spacer()
                    Image(systemName: "arrow.counterclockwise")
                        .symbolRenderingMode(.hierarchical)
                        .imageScale(.medium)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.generalDeveloperResetDefaults)
            .accessibilityAddTraits(.isButton)

            Button {
                showsFactoryResetConfirmation = true
            } label: {
                HStack(spacing: .spacingS) {
                    Text(L10n.settingsDeveloperFactoryReset)
                        .textStyle(.body1)
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .symbolRenderingMode(.hierarchical)
                        .imageScale(.medium)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.settingsDeveloperFactoryReset)
            .accessibilityAddTraits(.isButton)
        } header: {
            Text(L10n.generalMoreSectionDeveloper)
                .textStyle(.title3)
                .accessibilityAddTraits(.isHeader)
        }
    }

    /// The developer section wrapped with all alert and sheet presenters.
    private var developerSectionWithPresenters: some View {
        developerSectionBody
            .listRowBackground(Color.aListBackground)
            .alert(
                L10n.generalDeveloperResetDefaultsTitle,
                isPresented: $showsResetDefaultsConfirmation
            ) {
                Button(L10n.generalCancel, role: .cancel) {}
                Button(L10n.generalDeveloperResetDefaultsConfirm, role: .destructive) {
                    onResetDefaults(managedObjectContext)
                }
            } message: {
                Text(L10n.generalDeveloperResetDefaultsMessage)
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
            .alert(
                L10n.settingsDeveloperSeedData,
                isPresented: $showsSeedResultAlert
            ) {
                Button(L10n.generalOk, role: .cancel) {}
            } message: {
                Text(L10n.generalListEntryCount(seededRecordCount))
            }
            .sheet(isPresented: $showsPurchaseMetadataSheet) {
                purchaseMetadataSheet
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
    }
}

/// Provides helper logic for the iOS developer debug section.
private extension MoreMenuDebugDeveloperSection {
    /// Represents one product metadata row displayed in the developer sheet.
    struct PurchaseMetadataEntry: Identifiable {
        /// The stable identifier for list rendering.
        let id: String
        /// The user-facing localized product title.
        let displayName: String
        /// The localized StoreKit display price.
        let displayPrice: String
        /// The product description configured in App Store Connect.
        let description: String
        /// The product type as string for diagnostics.
        let typeName: String
    }

    /// The sheet that shows loaded StoreKit product metadata for diagnostics.
    var purchaseMetadataSheet: some View {
        NavigationStack {
            List {
                if isLoadingPurchaseMetadata {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if purchaseMetadataEntries.isEmpty {
                    VStack(alignment: .leading, spacing: .spacingXS) {
                        Text("Keine Metadaten geladen")
                            .textStyle(.body1)
                            .foregroundStyle(Color.aPrimary)
                        Text("Tippe auf Aktualisieren, um StoreKit-Produkte erneut zu laden.")
                            .textStyle(.body3)
                            .foregroundStyle(Color.aPrimary)
                    }
                    .padding(.vertical, .spacingXS)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(purchaseMetadataEntries) { entry in
                        VStack(alignment: .leading, spacing: .spacingXS) {
                            Text(entry.displayName)
                                .textStyle(.body1)
                                .foregroundStyle(Color.aPrimary)
                            Text(entry.displayPrice)
                                .textStyle(.body3)
                                .foregroundStyle(Color.aPrimary)
                            Text(entry.id)
                                .textStyle(.body3)
                                .foregroundStyle(Color.aPrimary)
                            Text(entry.typeName)
                                .textStyle(.body3)
                                .foregroundStyle(Color.aPrimary)
                            Text(entry.description)
                                .textStyle(.body3)
                                .foregroundStyle(Color.aPrimary)
                        }
                        .padding(.vertical, .spacingXS)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(L10n.settingsMorePurchasesTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await reloadPurchaseMetadata() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoadingPurchaseMetadata)
                    .accessibilityLabel(L10n.settingsMoreRestorePurchases)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.generalOk) {
                        showsPurchaseMetadataSheet = false
                    }
                }
            }
            .task {
                await reloadPurchaseMetadata()
            }
        }
    }

    /// Loads StoreKit products and maps them into debug metadata rows.
    func reloadPurchaseMetadata() async {
        guard isLoadingPurchaseMetadata == false else { return }
        isLoadingPurchaseMetadata = true
        didFailLoadingPurchaseMetadata = false
        defer { isLoadingPurchaseMetadata = false }

        #if canImport(StoreKit)
        do {
            let products = try await Product.products(for: PurchaseProductID.allPaywallIdentifiers)
            purchaseMetadataEntries = products.map { product in
                PurchaseMetadataEntry(
                    id: product.id,
                    displayName: product.displayName,
                    displayPrice: product.displayPrice,
                    description: product.description,
                    typeName: String(describing: product.type)
                )
            }
            .sorted { lhs, rhs in
                lhs.id < rhs.id
            }
        } catch {
            didFailLoadingPurchaseMetadata = true
            purchaseMetadataEntries = []
        }
        #else
        purchaseMetadataEntries = []
        #endif
    }

    /// Deletes all Core Data records from every entity in the current store.
    func clearDatabase() {
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
    func factoryResetAndExit() {
        DeveloperDatabaseResetService.resetStoreAndExit(managedObjectContext: managedObjectContext)
    }
}
#endif
#endif
