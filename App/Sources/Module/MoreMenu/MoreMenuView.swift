//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI
#if canImport(Darwin)
import Darwin
#endif
#if os(macOS)
import AppKit
#endif

/// A view that displays the "More" menu sections and entries.
@MainActor
struct MoreMenuView: View {
    /// The view model driving More menu state and actions.
    @State var viewModel = MoreMenuViewModel()

    #if DEBUG && os(iOS)
    /// Controls presentation of the developer onboarding preview.
    @State var showsDeveloperOnboardingPreview: Bool = false
    #endif

    /// The body of the more menu view.
    var body: some View {
        List {
            Section {
                #if os(iOS) && !targetEnvironment(macCatalyst)
                NavigationLink(value: NavigationStackRoute.module(.peerSyncIntro)) {
                    HStack(spacing: .spacingS) {
                        Text(viewModel.transferButtonTitle)
                            .textStyle(.body1)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(viewModel.transferButtonTitle)
                #else
                NavigationLink(value: NavigationStackRoute.module(.peerSyncIntro)) {
                    HStack(spacing: .spacingS) {
                        Text(viewModel.transferButtonTitle)
                            .textStyle(.body1)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(viewModel.transferButtonTitle)
                #endif

                NavigationLink(value: NavigationStackRoute.module(.export)) {
                    HStack(spacing: .spacingS) {
                        Text(L10n.generalMoreExportTitle)
                            .textStyle(.body1)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(L10n.generalMoreExportTitle)

                NavigationLink(value: NavigationStackRoute.module(.importData)) {
                    HStack(spacing: .spacingS) {
                        Text(L10n.generalMoreImportTitle)
                            .textStyle(.body1)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(L10n.generalMoreImportTitle)

                NavigationLink(value: NavigationStackRoute.module(.icloud)) {
                    HStack(spacing: .spacingS) {
                        Text("iCloud")
                            .textStyle(.body1)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("iCloud")
                .accessibilityAddTraits(.isButton)
            } header: {
                Text(L10n.generalMoreSectionExport)
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)
            }
            .listRowBackground(Color.aListBackground)

            Section {
                NavigationLink(value: NavigationStackRoute.module(.billingSettings)) {
                    HStack(spacing: .spacingS) {
                        Text("Billing")
                            .textStyle(.body1)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Billing")
                .accessibilityAddTraits(.isButton)

                NavigationLink(value: NavigationStackRoute.module(.invoicingSettings)) {
                    HStack(spacing: .spacingS) {
                        Text("Invoicing")
                            .textStyle(.body1)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Invoicing")
                .accessibilityAddTraits(.isButton)

                NavigationLink(value: NavigationStackRoute.module(.activitySettings)) {
                    HStack(spacing: .spacingS) {
                        Text(L10n.generalManagementActivities)
                            .textStyle(.body1)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(L10n.generalManagementActivities)
                .accessibilityAddTraits(.isButton)

                NavigationLink(value: NavigationStackRoute.module(.costCentreSettings)) {
                    HStack(spacing: .spacingS) {
                        Text(L10n.generalManagementCostCentres)
                            .textStyle(.body1)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(L10n.generalManagementCostCentres)
                .accessibilityAddTraits(.isButton)

                NavigationLink(value: NavigationStackRoute.module(.terminologySettings)) {
                    HStack(spacing: .spacingS) {
                        Text(L10n.managementTerminologyTitle)
                            .textStyle(.body1)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(L10n.managementTerminologyTitle)
                .accessibilityAddTraits(.isButton)
                #if os(iOS)
                Button {
                    viewModel.showsAppearanceSheet = true
                } label: {
                    HStack(spacing: .spacingS) {
                        Text(L10n.generalMoreAppearanceTitle)
                            .textStyle(.body1)
                        Spacer()
                        Text(viewModel.selectedAppearanceOption.localizedTitle)
                            .textStyle(.body1)
                            .foregroundStyle(Color.accentColor)
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundStyle(Color.accentColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.generalMoreAppearanceTitle)
                .accessibilityValue(viewModel.selectedAppearanceOption.localizedTitle)
                .accessibilityAddTraits(.isButton)

                Toggle(isOn: $viewModel.isHapticFeedbackEnabled) {
                    Text(L10n.settingsMoreHapticFeedbackTitle)
                        .textStyle(.body1)
                }
                .tint(Color.accentColor)
                .accessibilityLabel(L10n.settingsMoreHapticFeedbackTitle)
                #endif
            } header: {
                Text(L10n.generalMoreSectionSettings)
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)
            }
            .listRowBackground(Color.aListBackground)

            Section {
                NavigationLink(value: NavigationStackRoute.module(.purchases)) {
                    HStack(spacing: .spacingS) {
                        Text(L10n.settingsMorePurchasesTitle)
                            .textStyle(.body1)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(L10n.settingsMorePurchasesTitle)
                .accessibilityAddTraits(.isButton)

                NavigationLink(value: NavigationStackRoute.module(.imprint)) {
                    Text(L10n.generalMoreImprint)
                        .textStyle(.body1)
                }
                .accessibilityLabel(L10n.generalMoreImprint)
                .accessibilityAddTraits(.isButton)

                NavigationLink(value: NavigationStackRoute.module(.privacyPolicy)) {
                    Text(L10n.generalMorePrivacy)
                        .textStyle(.body1)
                }
                .accessibilityLabel(L10n.generalMorePrivacy)
                .accessibilityAddTraits(.isButton)

                Button {
                    Task {
                        await AppStoreReviewManager.requestReviewManually()
                    }
                } label: {
                    HStack(spacing: .spacingS) {
                        Text(L10n.generalMoreRateApp)
                            .textStyle(.body1)
                        Spacer()
                        Image(systemName: "paperplane.fill")
                            .symbolRenderingMode(.hierarchical)
                            .imageScale(.medium)
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.generalMoreRateApp)
                .accessibilityAddTraits(.isButton)
            } header: {
                Text(L10n.generalMoreSectionInfo)
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)
            }
            .listRowBackground(Color.aListBackground)

            #if DEBUG
            developerSection
            #endif
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        .listRowSeparator(.hidden)
        .listRowSeparatorTint(.clear)
        .listSectionSeparator(.hidden)
        .selectionDisabled(true)
        .focusable(false)
        #endif
        .scrollContentBackground(.hidden)
        .background(Color.aBackground)
        .foregroundStyle(Color.aPrimary)
        .navigationTitle(L10n.settingsMoreTitle)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showsAppearanceSheet) {
                appearanceSelectionSheet
                    .presentationDetents([.height(240)])
                    .presentationDragIndicator(.visible)
            }
        #endif
            .alert(L10n.errorBackupExportTitle, isPresented: $viewModel.showsExportErrorAlert) {
                Button(L10n.generalOk, role: .cancel) {}
            } message: {
                Text(viewModel.exportErrorMessage)
            }
        #if os(iOS)
            .sheet(isPresented: Binding(
                get: { viewModel.exportFileURL != nil },
                set: { isPresented in
                    if isPresented == false {
                        viewModel.exportFileURL = nil
                    }
                }
            )) {
                if let exportFileURL = viewModel.exportFileURL {
                    ActivityShareSheet(activityItems: [exportFileURL])
                }
            }
        #if DEBUG
            .fullScreenCover(isPresented: $showsDeveloperOnboardingPreview) {
                OnboardingView {
                    showsDeveloperOnboardingPreview = false
                }
            }
        #endif
        #endif
    }
}
