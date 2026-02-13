//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Provides an order-first entry into client-specific rate management.
@MainActor
struct ClientRatesEntryView: View {
    /// The client for which order rates are managed.
    let client: Client

    /// Fetches all orders for this entry screen.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) private var fetchedOrders: FetchedResults<Order>

    /// Renders the client rates entry body.
    var body: some View {
        List {
            Section {
                if clientOrders.isEmpty {
                    Text(L10n.generalNoData)
                        .textStyle(.body3)
                        .foregroundStyle(Color.secondary)
                } else {
                    ForEach(clientOrders, id: \.objectID) { order in
                        NavigationLink(destination: OrderRatesListView(order: order)) {
                            orderRow(order)
                        }
                        .listRowBackground(Color.aListBackground)
                    }
                }
            } header: {
                Text(L10n.generalManagementOrders)
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)
            }
            .listRowBackground(Color.aListBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.aBackground)
        .navigationTitle(normalized(client.name))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Returns all orders linked to the selected client.
    private var clientOrders: [Order] {
        fetchedOrders.filter { $0.client?.objectID == client.objectID }
    }

    /// Renders one order row with rate-status indicator.
    ///
    /// - Parameter order: The order displayed in the row.
    /// - Returns: A styled order row.
    private func orderRow(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: .spacingXXS) {
            Text(normalized(order.name))
                .textStyle(.body1)
                .foregroundStyle(Color.aPrimary)

            if let code = order.code?.trimmingCharacters(in: .whitespacesAndNewlines), code.isEmpty == false {
                Text(code)
                    .textStyle(.body3)
                    .foregroundStyle(Color.secondary)
            }

            Text(rateStatus(for: order))
                .textStyle(.body3)
                .foregroundStyle(Color.secondary)
        }
    }

    /// Returns one compact rate-status text.
    ///
    /// - Parameter order: The order to inspect.
    /// - Returns: A short status string.
    private func rateStatus(for order: Order) -> String {
        let orderRates = order.rates ?? []
        let hasAnyRate = orderRates.isEmpty == false
        let hasDefault = orderRates.contains { $0.is_default?.boolValue ?? false }

        if hasDefault {
            return L10n.generalStatus
        }
        if hasAnyRate {
            return L10n.generalManagementRates
        }
        return L10n.generalNoData
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
