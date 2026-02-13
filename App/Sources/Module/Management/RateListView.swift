//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Lists order rates and allows creating new rates from templates.
@MainActor
struct RateListView: View {
    /// The managed object context used for updates.
    @Environment(\.managedObjectContext) private var viewContext

    /// Fetches active orders for destination selection.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
        predicate: NSPredicate(format: "(is_active == nil) OR (is_active == YES)")
    ) private var activeOrders: FetchedResults<Order>

    /// Fetches all rates to filter by selected order.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "updated_at", ascending: false)]
    ) private var fetchedRates: FetchedResults<Rates>

    /// Fetches templates for apply flow.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) private var fetchedTemplates: FetchedResults<RateTemplate>

    /// Stores the currently selected order.
    @State private var selectedOrder: Order?

    /// Controls presentation of template-apply sheet.
    @State private var showsTemplateSheet = false

    /// Stores the latest apply error text.
    @State private var applyErrorMessage: String = ""

    /// Controls the apply-error alert.
    @State private var showsApplyErrorAlert = false

    /// Renders the order rates view.
    var body: some View {
        List {
            Section {
                Picker("Order", selection: $selectedOrder) {
                    Text(L10n.generalSelectPlaceholder).tag(Order?.none)
                    ForEach(activeOrders, id: \.objectID) { order in
                        Text(displayOrderName(order))
                            .tag(order as Order?)
                    }
                }
                .pickerStyle(.menu)
                .textStyle(.body1)
            } header: {
                Text("Order Rates")
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)
            }
            .listRowBackground(Color.aListBackground)

            Section {
                if selectedOrderRates.isEmpty {
                    Text(L10n.generalNoData)
                        .textStyle(.body3)
                        .foregroundStyle(Color.secondary)
                } else {
                    ForEach(selectedOrderRates, id: \.objectID) { rate in
                        rateRow(rate)
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
        .navigationTitle(L10n.generalManagementRates)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedOrder == nil {
                selectedOrder = activeOrders.first
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(destination: RateTemplateListView()) {
                    Text("Rate Templates")
                        .textStyle(.body3)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add from Template") {
                    showsTemplateSheet = true
                }
                .disabled(selectedOrder == nil || availableTemplatesForApply.isEmpty)
            }
        }
        .sheet(isPresented: $showsTemplateSheet) {
            NavigationStack {
                List {
                    ForEach(availableTemplatesForApply, id: \.objectID) { template in
                        Button {
                            apply(template)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: .spacingXXS) {
                                    Text(displayTemplateName(template))
                                        .textStyle(.body1)
                                        .foregroundStyle(Color.aPrimary)
                                    Text(displayTemplateBillingType(template))
                                        .textStyle(.body3)
                                        .foregroundStyle(Color.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.aListBackground)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.aBackground)
                .navigationTitle("Add from Template")
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
        .alert("Apply Template", isPresented: $showsApplyErrorAlert) {
            Button(L10n.generalOk, role: .cancel) {}
        } message: {
            Text(applyErrorMessage)
        }
    }
}

private extension RateListView {
    /// Returns rates linked to the selected order.
    var selectedOrderRates: [Rates] {
        guard let selectedOrder else {
            return []
        }
        return fetchedRates
            .filter { $0.order?.objectID == selectedOrder.objectID }
            .sorted { lhs, rhs in
                let lhsDate = lhs.updated_at ?? .distantPast
                let rhsDate = rhs.updated_at ?? .distantPast
                return lhsDate > rhsDate
            }
    }

    /// Returns templates available for apply flow with profile/share scoping and active filter.
    var availableTemplatesForApply: [RateTemplate] {
        let filteredByActive = fetchedTemplates.filter { $0.is_active?.boolValue ?? true }
        guard let selectedProfile = selectedOrder?.profile else {
            return filteredByActive
        }

        return filteredByActive.filter { template in
            let belongsToProfile = template.profile?.objectID == selectedProfile.objectID
            let isShared = template.shared_profile?.boolValue ?? true
            return belongsToProfile || isShared
        }
    }

    /// Formats one order display name.
    ///
    /// - Parameter order: The order that should be shown.
    /// - Returns: A non-empty order name.
    func displayOrderName(_ order: Order) -> String {
        let trimmed = order.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.generalUnknown : trimmed
    }

    /// Returns one safe template name.
    func displayTemplateName(_ template: RateTemplate) -> String {
        let trimmed = template.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.generalUnknown : trimmed
    }

    /// Returns one human-readable billing-type label for templates.
    func displayTemplateBillingType(_ template: RateTemplate) -> String {
        guard let billingType = BillingType(coreDataValue: template.billing_type) else {
            return "-"
        }
        switch billingType {
        case .hourly:
            return "Hourly"
        case .fixed:
            return "Fixed"
        case .none:
            return "None"
        }
    }

    /// Renders one rate row.
    ///
    /// - Parameter rate: The rate that should be shown.
    /// - Returns: A list row with key fields.
    @ViewBuilder
    func rateRow(_ rate: Rates) -> some View {
        VStack(alignment: .leading, spacing: .spacingXXS) {
            Text(rate.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? rate.name ?? "" : L10n.generalUnknown)
                .textStyle(.body1)
                .foregroundStyle(Color.aPrimary)
            Text(displayRateDetails(rate))
                .textStyle(.body3)
                .foregroundStyle(Color.secondary)
        }
    }

    /// Builds one detail line for a rate.
    ///
    /// - Parameter rate: The source rate.
    /// - Returns: A compact detail string.
    func displayRateDetails(_ rate: Rates) -> String {
        guard let billingType = BillingType(coreDataValue: rate.billing_type) else {
            return "-"
        }
        switch billingType {
        case .hourly:
            let value = rate.hourly_rate?.doubleValue ?? 0
            return "Hourly: \(String(format: "%.2f", value))"
        case .fixed:
            let value = rate.fixed_amount?.doubleValue ?? 0
            return "Fixed: \(String(format: "%.2f", value))"
        case .none:
            return "None"
        }
    }

    /// Applies one template to the selected order and closes the sheet.
    ///
    /// - Parameter template: The selected template to copy.
    func apply(_ template: RateTemplate) {
        guard let selectedOrder else {
            return
        }

        do {
            try RateTemplateManager.applyTemplate(template, to: selectedOrder, in: viewContext)
            showsTemplateSheet = false
        } catch {
            applyErrorMessage = error.localizedDescription
            showsApplyErrorAlert = true
        }
    }
}
