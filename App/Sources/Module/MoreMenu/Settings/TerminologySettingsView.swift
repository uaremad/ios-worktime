//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Renders terminology settings for one global counterparty wording.
@MainActor
struct TerminologySettingsView: View {
    /// Indicates whether screen-specific toolbar controls should be shown.
    private let showsNavigationToolbar: Bool

    /// Dismiss action used to leave the screen.
    @Environment(\.dismiss) private var dismiss

    /// The managed object context used for loading and saving.
    @Environment(\.managedObjectContext) private var context

    /// The state and actions backing this screen.
    @State private var viewModel: TerminologySettingsViewModel

    /// Controls presentation of the unsaved-changes alert.
    @State private var showsUnsavedChangesAlert: Bool = false

    /// Creates one terminology settings screen.
    ///
    /// - Parameters:
    ///   - profile: Optional profile scope for terminology values.
    ///   - showsNavigationToolbar: Controls visibility of the local toolbar controls.
    init(profile: Profile? = nil, showsNavigationToolbar: Bool = true) {
        self.showsNavigationToolbar = showsNavigationToolbar
        _viewModel = State(initialValue: TerminologySettingsViewModel(
            profile: profile,
            configurationService: .shared,
            settingsStorage: .shared
        ))
    }

    /// The screen content.
    var body: some View {
        Form {
            Section {
                Picker(L10n.managementTerminologyPickerTerm, selection: selectedOptionBinding) {
                    ForEach(viewModel.nonFreeTextOptions) { option in
                        Text(option.singular)
                            .tag(option.id)
                    }
                    Divider()
                    Text(viewModel.freeTextOption.singular)
                        .tag(viewModel.freeTextOption.id)
                }
                .tint(.accentColor)

                VStack(alignment: .leading, spacing: .spacingXXS) {
                    Text(L10n.managementTerminologyFieldSingularTitle)
                        .textStyle(.body3)
                        .foregroundStyle(Color.accentColor)
                    HStack(spacing: .spacingXS) {
                        TextField(L10n.managementTerminologyFieldCurrentName, text: singularBinding)
                            .textStyle(.body1)
                            .textInputAutocapitalization(.words)
                            .disabled(viewModel.isFreeTextSelection == false)

                        if viewModel.isFreeTextSelection, viewModel.selectedSingular.isEmpty == false {
                            Button {
                                viewModel.clearFreeTextSingular(context: context)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.timerecordInputClear)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: .spacingXXS) {
                    Text(L10n.managementTerminologyFieldPluralTitle)
                        .textStyle(.body3)
                        .foregroundStyle(Color.accentColor)
                    HStack(spacing: .spacingXS) {
                        TextField(L10n.managementTerminologyFieldPluralName, text: pluralBinding)
                            .textStyle(.body1)
                            .textInputAutocapitalization(.words)
                            .disabled(viewModel.isFreeTextSelection == false)

                        if viewModel.isFreeTextSelection, viewModel.selectedPlural.isEmpty == false {
                            Button {
                                viewModel.clearFreeTextPlural(context: context)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.timerecordInputClear)
                        }
                    }
                }
            } header: {
                Text(L10n.managementTerminologySectionCounterparty)
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)
            } footer: {
                Text(L10n.managementTerminologyFooterCounterparty)
                    .textStyle(.body3)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.aListBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Color.aBackground)
        .navigationTitle(L10n.managementTerminologyTitle)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if showsNavigationToolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        handleLeaveAttempt()
                    } label: {
                        Image(systemName: "chevron.backward")
                    }
                    .accessibilityLabel(L10n.generalCancel)
                }
                if viewModel.isFreeTextSelection {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.saveFromToolbar(context: context)
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .accessibilityLabel(L10n.generalSave)
                    }
                }
            }
        }
        .alert(L10n.managementTerminologyAlertInfoTitle, isPresented: statusAlertBinding) {
            Button(L10n.generalOk, role: .cancel) {}
        } message: {
            Text(viewModel.statusMessage)
        }
        .alert(L10n.managementTerminologyUnsavedTitle, isPresented: $showsUnsavedChangesAlert) {
            Button(L10n.managementTerminologyUnsavedSaveAndLeave) {
                if viewModel.saveFreeTextForLeaving(context: context) {
                    dismiss()
                }
            }
            Button(L10n.managementTerminologyUnsavedDiscard, role: .destructive) {
                dismiss()
            }
            Button(L10n.generalCancel, role: .cancel) {}
        } message: {
            Text(L10n.managementTerminologyUnsavedMessage)
        }
        .task {
            viewModel.loadIfNeeded(context: context)
        }
        .onChange(of: viewModel.selectedOptionID) { _, _ in
            guard viewModel.isFreeTextSelection == false else {
                return
            }
            viewModel.saveSilently(context: context)
        }
    }
}

private extension TerminologySettingsView {
    /// Binding used for selecting one terminology option.
    var selectedOptionBinding: Binding<String> {
        Binding(
            get: { viewModel.selectedOptionID },
            set: { newValue in
                viewModel.selectOption(id: newValue)
            }
        )
    }

    /// Binding used for editing the singular counterparty term.
    var singularBinding: Binding<String> {
        Binding(
            get: { viewModel.selectedSingular },
            set: { newValue in
                viewModel.selectedSingular = newValue
            }
        )
    }

    /// Binding used for editing the plural counterparty term.
    var pluralBinding: Binding<String> {
        Binding(
            get: { viewModel.selectedPlural },
            set: { newValue in
                viewModel.selectedPlural = newValue
            }
        )
    }

    /// Binding controlling presentation of the status alert.
    var statusAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showsStatusAlert },
            set: { newValue in
                viewModel.showsStatusAlert = newValue
            }
        )
    }

    /// Handles leave attempts with validation and unsaved-check guards.
    func handleLeaveAttempt() {
        guard viewModel.isFreeTextSelection else {
            dismiss()
            return
        }

        guard viewModel.hasInvalidFreeTextValues == false else {
            viewModel.statusMessage = L10n.managementTerminologyErrorBothRequired
            viewModel.showsStatusAlert = true
            return
        }

        guard viewModel.hasUnsavedFreeTextChanges else {
            dismiss()
            return
        }

        showsUnsavedChangesAlert = true
    }
}
