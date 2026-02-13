//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Lists and manages rates for one selected order.
@MainActor
struct OrderRatesListView: View {
    /// The managed object context used for updates.
    @Environment(\.managedObjectContext) private var viewContext

    /// The selected order scope.
    let order: Order

    /// Fetches all rates for in-memory filtering.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "updated_at", ascending: false)]
    ) private var fetchedRates: FetchedResults<Rates>

    /// Fetches available templates for apply flow.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) private var fetchedTemplates: FetchedResults<RateTemplate>

    /// Stores selected rate for edit mode.
    @State private var selectedRate: Rates?

    /// Controls create-sheet presentation.
    @State private var showsCreateSheet = false

    /// Controls template-sheet presentation.
    @State private var showsTemplateSheet = false

    /// Stores apply-flow error message.
    @State private var errorMessage: String = ""

    /// Controls error alert presentation.
    @State private var showsErrorAlert = false

    /// Renders the order rates list body.
    var body: some View {
        List {
            Section {
                if orderRates.isEmpty {
                    Text(L10n.generalNoData)
                        .textStyle(.body3)
                        .foregroundStyle(Color.secondary)
                } else {
                    ForEach(orderRates, id: \.objectID) { rate in
                        Button {
                            selectedRate = rate
                        } label: {
                            rateRow(rate)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.aListBackground)
                    }
                }
            } header: {
                Text(L10n.generalManagementRates)
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)
            }
            .listRowBackground(Color.aListBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.aBackground)
        .navigationTitle(normalized(order.name))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(destination: RateTemplateListView()) {
                    Text(L10n.generalManagementRates)
                        .textStyle(.body3)
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showsTemplateSheet = true
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .disabled(availableTemplates.isEmpty)
                .accessibilityLabel(L10n.generalManagementRates)

                Button {
                    showsCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(L10n.generalManagementRates)
            }
        }
        .sheet(isPresented: $showsCreateSheet) {
            RateEditView(order: order)
        }
        .sheet(item: $selectedRate) { rate in
            RateEditView(order: order, rate: rate)
        }
        .sheet(isPresented: $showsTemplateSheet) {
            NavigationStack {
                List {
                    ForEach(availableTemplates, id: \.objectID) { template in
                        Button {
                            applyTemplate(template)
                        } label: {
                            VStack(alignment: .leading, spacing: .spacingXXS) {
                                Text(normalized(template.name))
                                    .textStyle(.body1)
                                    .foregroundStyle(Color.aPrimary)
                                Text(template.billing_type ?? L10n.generalUnknown)
                                    .textStyle(.body3)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.aListBackground)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.aBackground)
                .navigationTitle(L10n.generalManagementRates)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(L10n.generalCancel) {
                            showsTemplateSheet = false
                        }
                    }
                }
            }
        }
        .alert(L10n.generalDetails, isPresented: $showsErrorAlert) {
            Button(L10n.generalOk, role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    /// Returns all rates linked to the selected order.
    private var orderRates: [Rates] {
        fetchedRates.filter { $0.order?.objectID == order.objectID }
    }

    /// Returns all templates visible for current profile scope.
    private var availableTemplates: [RateTemplate] {
        let selectedProfile = order.profile ?? ManagementScopeResolver.selectedProfile(in: viewContext)

        return fetchedTemplates.filter { template in
            let isActive = template.is_active?.boolValue ?? true
            guard isActive else {
                return false
            }

            return ManagementScopeResolver.isVisible(
                entityProfile: template.profile,
                sharedProfileFlag: template.shared_profile,
                selectedProfile: selectedProfile
            )
        }
    }

    /// Renders one compact rate row.
    ///
    /// - Parameter rate: The rate to render.
    /// - Returns: A styled row with details.
    private func rateRow(_ rate: Rates) -> some View {
        VStack(alignment: .leading, spacing: .spacingXXS) {
            Text(normalized(rate.name))
                .textStyle(.body1)
                .foregroundStyle(Color.aPrimary)

            Text(rate.billing_type ?? L10n.generalUnknown)
                .textStyle(.body3)
                .foregroundStyle(Color.secondary)

            if rate.is_default?.boolValue ?? false {
                Text(L10n.generalStatus)
                    .textStyle(.body3)
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    /// Applies one selected template to this order.
    ///
    /// - Parameter template: The template to copy into a new rate.
    private func applyTemplate(_ template: RateTemplate) {
        do {
            try RateTemplateManager.applyTemplate(template, to: order, in: viewContext)
            showsTemplateSheet = false
        } catch {
            errorMessage = error.localizedDescription
            showsErrorAlert = true
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
