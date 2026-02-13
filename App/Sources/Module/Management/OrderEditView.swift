//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Creates or edits one client-scoped order.
@MainActor
struct OrderEditView: View {
    /// The managed object context used for persistence.
    @Environment(\.managedObjectContext) private var viewContext

    /// Dismiss callback for this sheet.
    @Environment(\.dismiss) private var dismiss

    /// The client assigned to this order.
    let client: Client

    /// Optional existing order in edit mode.
    let order: Order?

    /// Fetches cost centres for optional assignment.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) private var fetchedCostCentres: FetchedResults<CostCentre>

    /// The order name input.
    @State private var name: String

    /// The order code input.
    @State private var code: String

    /// The order notice input.
    @State private var notice: String

    /// The selected optional cost centre.
    @State private var selectedCostCentre: CostCentre?

    /// Whether `valid_from` is enabled.
    @State private var hasValidFrom: Bool

    /// The selected `valid_from` date.
    @State private var validFrom: Date

    /// Whether `valid_to` is enabled.
    @State private var hasValidTo: Bool

    /// The selected `valid_to` date.
    @State private var validTo: Date

    /// The active-state toggle.
    @State private var isActive: Bool

    /// The shared-profile toggle.
    @State private var isShared: Bool

    /// Stores save error messages.
    @State private var validationMessage: String = ""

    /// Controls save-error alert presentation.
    @State private var showsValidationAlert = false

    /// Creates one order edit view.
    ///
    /// - Parameters:
    ///   - client: The preselected client.
    ///   - order: Optional existing order for edit mode.
    init(client: Client, order: Order? = nil) {
        self.client = client
        self.order = order
        _name = State(initialValue: order?.name ?? "")
        _code = State(initialValue: order?.code ?? "")
        _notice = State(initialValue: order?.notice ?? "")
        _selectedCostCentre = State(initialValue: order?.costCentre)
        _hasValidFrom = State(initialValue: order?.valid_from != nil)
        _validFrom = State(initialValue: order?.valid_from ?? Date())
        _hasValidTo = State(initialValue: order?.valid_to != nil)
        _validTo = State(initialValue: order?.valid_to ?? Date())
        _isActive = State(initialValue: order?.is_active?.boolValue ?? true)
        _isShared = State(initialValue: order?.shared_profile?.boolValue ?? true)
    }

    /// Renders the order edit form.
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L10n.clientName, text: $name)
                        .textStyle(.body1)
                        .foregroundStyle(Color.aPrimary)
                    TextField(L10n.clientExternalRef, text: $code)
                        .textStyle(.body1)
                        .foregroundStyle(Color.aPrimary)
                    TextField(L10n.generalComment, text: $notice)
                        .textStyle(.body1)
                        .foregroundStyle(Color.aPrimary)

                    Picker(L10n.generalManagementCostCentres, selection: $selectedCostCentre) {
                        Text(L10n.generalNone).tag(CostCentre?.none)
                        ForEach(scopedCostCentres, id: \.objectID) { costCentre in
                            Text(normalized(costCentre.name))
                                .tag(costCentre as CostCentre?)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle(L10n.generalActive, isOn: $isActive)
                    Toggle(L10n.clientSharedProfile, isOn: $isShared)
                } header: {
                    Text(L10n.generalDetails)
                        .textStyle(.title3)
                        .accessibilityAddTraits(.isHeader)
                }
                .listRowBackground(Color.aListBackground)

                Section {
                    Toggle(L10n.exportDateRangeFrom, isOn: $hasValidFrom)
                    if hasValidFrom {
                        DatePicker(
                            L10n.exportDateRangeFrom,
                            selection: $validFrom,
                            displayedComponents: .date
                        )
                    }

                    Toggle(L10n.exportDateRangeTo, isOn: $hasValidTo)
                    if hasValidTo {
                        DatePicker(
                            L10n.exportDateRangeTo,
                            selection: $validTo,
                            displayedComponents: .date
                        )
                    }
                } header: {
                    Text(L10n.generalStatus)
                        .textStyle(.title3)
                        .accessibilityAddTraits(.isHeader)
                }
                .listRowBackground(Color.aListBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Color.aBackground)
            .navigationTitle(order == nil ? L10n.generalSave : L10n.generalEdit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.generalCancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.generalSave) {
                        saveOrder()
                    }
                }
            }
            .alert(L10n.generalDetails, isPresented: $showsValidationAlert) {
                Button(L10n.generalOk, role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    /// Returns cost centres visible for the current client scope.
    private var scopedCostCentres: [CostCentre] {
        let selectedProfile = ManagementScopeResolver.selectedProfile(in: viewContext)
        return fetchedCostCentres.filter { costCentre in
            ManagementScopeResolver.isVisible(
                entityProfile: costCentre.profile,
                sharedProfileFlag: costCentre.shared_profile,
                selectedProfile: selectedProfile
            )
        }
    }

    /// Saves the order using `OrderManager` and dismisses on success.
    private func saveOrder() {
        let orderToSave = order ?? Order.insert(into: viewContext)
        orderToSave.client = client
        orderToSave.profile = order?.profile ?? client.profile ?? ManagementScopeResolver.selectedProfile(in: viewContext)
        orderToSave.name = name
        orderToSave.code = code
        let normalizedNotice = notice.trimmingCharacters(in: .whitespacesAndNewlines)
        orderToSave.notice = normalizedNotice.isEmpty ? nil : normalizedNotice
        orderToSave.costCentre = selectedCostCentre
        orderToSave.valid_from = hasValidFrom ? validFrom : nil
        orderToSave.valid_to = hasValidTo ? validTo : nil
        orderToSave.is_active = NSNumber(value: isActive)
        orderToSave.shared_profile = NSNumber(value: isShared)

        do {
            try OrderManager.save(orderToSave, in: viewContext)
            dismiss()
        } catch {
            viewContext.rollback()
            validationMessage = error.localizedDescription
            showsValidationAlert = true
        }
    }

    /// Returns one normalized fallback for optional values.
    ///
    /// - Parameter value: The optional source value.
    /// - Returns: A non-empty display value.
    private func normalized(_ value: String?) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.generalUnknown : trimmed
    }
}
