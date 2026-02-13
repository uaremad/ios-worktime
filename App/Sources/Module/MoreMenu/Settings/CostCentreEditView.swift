//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// View for creating or editing a cost centre.
@MainActor
struct CostCentreEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let costCentre: CostCentre?

    @State private var name = ""
    @State private var externalRef = ""
    @State private var notice = ""
    @State private var selectedClient: Client?
    @State private var isActive = true
    @State private var sharedProfile = false
    @State private var showDuplicateNameAlert = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
        predicate: NSPredicate(format: "(is_active == nil) OR (is_active == YES)")
    ) private var availableClients: FetchedResults<Client>

    init(costCentre: CostCentre? = nil) {
        self.costCentre = costCentre
        _name = State(initialValue: costCentre?.name ?? "")
        _externalRef = State(initialValue: costCentre?.external_ref ?? "")
        _notice = State(initialValue: costCentre?.notice ?? "")
        _selectedClient = State(initialValue: nil)
        // Note: Active/Shared properties don't exist in current data model
        _isActive = State(initialValue: true)
        _sharedProfile = State(initialValue: false)
    }

    var body: some View {
        NavigationStack {
            Form(content: {
                Section {
                    TextField(L10n.costCentreName, text: $name)
                        .textStyle(.body1)
                        .foregroundStyle(Color.aPrimary)
                        .accessibilityLabel(L10n.costCentreName)
                    TextField(L10n.costCentreExternalRef, text: $externalRef)
                        .textStyle(.body1)
                        .foregroundStyle(Color.aPrimary)
                        .accessibilityLabel(L10n.costCentreExternalRef)
                    TextField(L10n.generalComment, text: $notice)
                        .textStyle(.body1)
                        .foregroundStyle(Color.aPrimary)
                        .accessibilityLabel(L10n.generalComment)
                } header: {
                    Text(L10n.generalDetails)
                        .textStyle(.title3)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text(L10n.managementCostCentreEditFooter)
                        .textStyle(.body3)
                        .foregroundStyle(Color.secondary)
                }
                .listRowBackground(Color.aListBackground)

                if availableClients.isEmpty == false {
                    Section {
                        Picker(L10n.costCentreScope, selection: $selectedClient) {
                            Text(L10n.costCentreScopeGlobal)
                                .textStyle(.body1)
                                .foregroundStyle(Color.aPrimary)
                                .tag(Client?.none)
                            ForEach(availableClients, id: \.self) { client in
                                Text(client.name ?? L10n.generalUnknown)
                                    .textStyle(.body1)
                                    .foregroundStyle(Color.aPrimary)
                                    .tag(client as Client?)
                            }
                        }
                        .pickerStyle(.menu)
                        .textStyle(.body1)
                        .foregroundStyle(Color.aPrimary)
                        .accessibilityLabel(L10n.costCentreScope)
                    } header: {
                        Text(L10n.generalScope)
                            .textStyle(.title3)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .listRowBackground(Color.aListBackground)
                }
            })
            .scrollContentBackground(.hidden)
            .background(Color.aBackground)
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.generalCancel) {
                        dismiss()
                    }
                    .accessibilityLabel(L10n.generalCancel)
                }
                #endif
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        save()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityLabel(L10n.generalSave)
                }
            }
            .alert(L10n.generalAlreadyTaken, isPresented: $showDuplicateNameAlert) {
                Button(L10n.generalOk, role: .cancel) {}
            } message: {
                Text(L10n.generalAlreadyTaken)
            }
        }
    }

    /// Returns the trimmed value for form comparisons and persistence.
    ///
    /// - Parameter value: The raw field value.
    /// - Returns: The trimmed field value.
    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Indicates whether no new input was entered in create mode.
    private var hasNoInputForCreation: Bool {
        normalized(name).isEmpty && normalized(externalRef).isEmpty && normalized(notice).isEmpty
    }

    /// Indicates whether the current fields are unchanged in edit mode.
    private var hasNoChangesForEditing: Bool {
        guard let costCentre else {
            return false
        }

        return normalized(name) == normalized(costCentre.name ?? "")
            && normalized(externalRef) == normalized(costCentre.external_ref ?? "")
            && normalized(notice) == normalized(costCentre.notice ?? "")
    }

    /// Indicates whether the save action should simply dismiss without persistence.
    private var shouldDismissWithoutSaving: Bool {
        if costCentre == nil {
            return hasNoInputForCreation
        }
        return hasNoChangesForEditing
    }

    /// Persists a unique cost centre or dismisses when no input was provided.
    private func save() {
        if shouldDismissWithoutSaving {
            dismiss()
            return
        }

        let trimmedName = normalized(name)
        guard !trimmedName.isEmpty else { return }

        // Check for duplicate name
        let fetchRequest = CostCentre.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", trimmedName)
        if let existingCostCentre = costCentre {
            fetchRequest.predicate = NSPredicate(format: "name == %@ AND self != %@", trimmedName, existingCostCentre)
        }

        do {
            let existingCostCentres = try viewContext.fetch(fetchRequest)
            if !existingCostCentres.isEmpty {
                showDuplicateNameAlert = true
                return
            }
        } catch {
            print("Error checking for duplicate cost centre: \(error)")
            return
        }

        let costCentreToSave = costCentre ?? CostCentre(context: viewContext)
        costCentreToSave.name = trimmedName
        let trimmedExternalRef = normalized(externalRef)
        let trimmedNotice = normalized(notice)
        costCentreToSave.external_ref = trimmedExternalRef.isEmpty ? nil : trimmedExternalRef
        costCentreToSave.notice = trimmedNotice.isEmpty ? nil : trimmedNotice
        // Note: client, isActive, sharedProfile, createdAt, updatedAt properties don't exist in current data model

        do {
            try viewContext.save()
            dismiss()
        } catch {
            // Handle error
            print("Error saving cost centre: \(error)")
        }
    }
}
