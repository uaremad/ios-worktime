//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Displays all orders linked to one client with search and active filters.
@MainActor
struct ClientOrdersListView: View {
    /// Supported order active-state filters.
    enum ActiveFilter: String, CaseIterable, Identifiable {
        /// Shows active orders only.
        case active
        /// Shows inactive orders only.
        case inactive
        /// Shows all orders.
        case all

        /// Stable identifier for picker usage.
        var id: String { rawValue }
    }

    /// The managed object context used by edit sheets.
    @Environment(\.managedObjectContext) private var viewContext

    /// The client scope for this order list.
    let client: Client

    /// Fetches all orders for in-memory filtering.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) private var fetchedOrders: FetchedResults<Order>

    /// Stores the order search query.
    @State private var searchText: String = ""

    /// Stores the selected active-state filter.
    @State private var filter: ActiveFilter = .active

    /// Controls create-sheet presentation.
    @State private var showsCreateSheet = false

    /// Stores selected order for edit-sheet presentation.
    @State private var selectedOrder: Order?

    /// Renders the order list body.
    var body: some View {
        List {
            Section {
                Picker(L10n.generalFilter, selection: $filter) {
                    Text(L10n.generalActive).tag(ActiveFilter.active)
                    Text(L10n.generalInactive).tag(ActiveFilter.inactive)
                    Text(L10n.generalAll).tag(ActiveFilter.all)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            Section {
                if visibleOrders.isEmpty {
                    Text(L10n.generalNoData)
                        .textStyle(.body3)
                        .foregroundStyle(Color.secondary)
                } else {
                    ForEach(visibleOrders, id: \.objectID) { order in
                        Button {
                            selectedOrder = order
                        } label: {
                            orderRow(order)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.aListBackground)
                    }
                }
            } header: {
                Text(L10n.clientRelatedOrders)
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)
            }
            .listRowBackground(Color.aListBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.aBackground)
        .searchable(text: $searchText, prompt: L10n.timerecordInputOrderSearchPlaceholder)
        .navigationTitle(normalized(client.name))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showsCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(L10n.generalManagementOrders)
            }
        }
        .sheet(isPresented: $showsCreateSheet) {
            OrderEditView(client: client)
        }
        .sheet(item: $selectedOrder) { order in
            OrderEditView(client: client, order: order)
        }
    }

    /// Returns orders that match client scope, active filter, and search text.
    private var visibleOrders: [Order] {
        fetchedOrders.filter { order in
            guard order.client?.objectID == client.objectID else {
                return false
            }

            let isActive = order.is_active?.boolValue ?? true
            switch filter {
            case .active where isActive == false:
                return false
            case .inactive where isActive:
                return false
            default:
                break
            }

            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard query.isEmpty == false else {
                return true
            }

            let name = order.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let code = order.code?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return name.localizedCaseInsensitiveContains(query) || code.localizedCaseInsensitiveContains(query)
        }
    }

    /// Renders one order row.
    ///
    /// - Parameter order: The order to display.
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
