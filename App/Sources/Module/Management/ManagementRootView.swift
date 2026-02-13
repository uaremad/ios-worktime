//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Displays clients as the primary management entrypoint with search and filters.
@MainActor
struct ManagementRootView: View {
    /// Defines available active-state filters.
    enum ActiveFilter: String, CaseIterable, Identifiable {
        case active
        case inactive
        case all

        /// Stable identifier for segmented picker rendering.
        var id: String { rawValue }
    }

    /// The managed object context used for all client actions.
    @Environment(\.managedObjectContext) private var viewContext

    #if os(iOS)
    /// Horizontal size class for adaptive layout decisions.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    /// Fetches all clients sorted by name.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) private var fetchedClients: FetchedResults<Client>

    /// Stores the current search query.
    @State private var searchText: String = ""

    /// Stores the selected active-state filter.
    @State private var activeFilter: ActiveFilter = .active

    /// Controls quick-add alert presentation.
    @State private var showsQuickAddAlert = false

    /// Stores the quick-add name input text.
    @State private var quickAddName: String = ""

    /// Stores quick-add validation text.
    @State private var quickAddValidationText: String = ""

    /// Controls presentation of quick-add validation alert.
    @State private var showsQuickAddValidationAlert = false

    /// Triggers direct navigation to the just-created client.
    @State private var createdClient: Client?

    /// Renders the management root body.
    var body: some View {
        Group {
            if visibleClients.isEmpty {
                ManagementEmptyStateView(
                    title: L10n.generalManagementClients,
                    message: L10n.generalNoData,
                    actionTitle: L10n.accessibilityAddClient
                ) {
                    openQuickAdd()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
            }
        }
        .navigationTitle(L10n.generalManagementClients)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: L10n.generalPlaceholderSearchClients)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    openQuickAdd()
                } label: {
                    Label(L10n.accessibilityAddClient, systemImage: "plus")
                }
                .accessibilityLabel(L10n.accessibilityAddClient)
            }
        }
        .navigationDestination(item: $createdClient) { client in
            ClientDetailView(client: client)
        }
        .alert(L10n.accessibilityAddClient, isPresented: $showsQuickAddAlert) {
            TextField(L10n.clientName, text: $quickAddName)
            Button(L10n.generalCancel, role: .cancel) {
                resetQuickAddState()
            }
            Button(L10n.generalSave) {
                createQuickClient()
            }
        } message: {
            Text(L10n.clientName)
        }
        .alert(L10n.generalDetails, isPresented: $showsQuickAddValidationAlert) {
            Button(L10n.generalOk, role: .cancel) {}
        } message: {
            Text(quickAddValidationText)
        }
    }

    /// Renders root content with filter controls and client presentation.
    private var content: some View {
        VStack(spacing: .spacingS) {
            filterBar
            clientPresentation
        }
        .padding(.horizontal, .spacingS)
        .padding(.vertical, .spacingXS)
    }

    /// Renders the active-state filter segmented picker.
    private var filterBar: some View {
        Picker(L10n.generalFilter, selection: $activeFilter) {
            Text(L10n.generalActive).tag(ActiveFilter.active)
            Text(L10n.generalInactive).tag(ActiveFilter.inactive)
            Text(L10n.generalAll).tag(ActiveFilter.all)
        }
        .pickerStyle(.segmented)
    }

    /// Renders either grid or list presentation depending on platform.
    @ViewBuilder
    private var clientPresentation: some View {
        #if os(iOS)
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: .spacingS) {
                ForEach(visibleClients, id: \.objectID) { client in
                    NavigationLink(destination: ClientDetailView(client: client)) {
                        clientCard(client)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, .spacingS)
        }
        #else
        List {
            ForEach(visibleClients, id: \.objectID) { client in
                NavigationLink(destination: ClientDetailView(client: client)) {
                    ClientRowView(client: client)
                }
                .listRowBackground(Color.aListBackground)
            }
        }
        .listStyle(.inset)
        #endif
    }

    #if os(iOS)
    /// Returns adaptive grid columns for iPhone and iPad layouts.
    private var gridColumns: [GridItem] {
        if horizontalSizeClass == .regular {
            return Array(repeating: GridItem(.flexible(), spacing: .spacingS), count: 3)
        }
        return Array(repeating: GridItem(.flexible(), spacing: .spacingS), count: 2)
    }
    #endif

    /// Renders one client card used on iOS grid layouts.
    ///
    /// - Parameter client: The client displayed by the card.
    /// - Returns: One tappable client card.
    private func clientCard(_ client: Client) -> some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            Text(displayClientName(client))
                .textStyle(.body1)
                .foregroundStyle(Color.aPrimary)
                .lineLimit(2)

            if let externalRef = client.external_ref?.trimmingCharacters(in: .whitespacesAndNewlines), externalRef.isEmpty == false {
                Text(externalRef)
                    .textStyle(.body3)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: .spacingXS)

            Text((client.is_active?.boolValue ?? true) ? L10n.generalActive : L10n.generalInactive)
                .textStyle(.body3)
                .foregroundStyle((client.is_active?.boolValue ?? true) ? Color.aPrimary : Color.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .padding(.spacingS)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadius, style: .continuous)
                .fill(Color.aListBackground)
        )
    }

    /// Returns clients after scope, filter, and search application.
    private var visibleClients: [Client] {
        let selectedProfile = ManagementScopeResolver.selectedProfile(in: viewContext)

        return fetchedClients.filter { client in
            guard ManagementScopeResolver.isVisible(
                entityProfile: client.profile,
                sharedProfileFlag: client.shared_profile,
                selectedProfile: selectedProfile
            ) else {
                return false
            }

            if activeFilter != .all {
                let isActive = client.is_active?.boolValue ?? true
                if activeFilter == .active, isActive == false {
                    return false
                }
                if activeFilter == .inactive, isActive {
                    return false
                }
            }

            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard query.isEmpty == false else {
                return true
            }

            let clientName = client.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let externalRef = client.external_ref?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return clientName.localizedCaseInsensitiveContains(query) || externalRef.localizedCaseInsensitiveContains(query)
        }
    }

    /// Returns one displayable client name.
    ///
    /// - Parameter client: The client to format.
    /// - Returns: Non-empty display text.
    private func displayClientName(_ client: Client) -> String {
        let trimmed = client.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.generalUnknown : trimmed
    }

    /// Opens the quick-add alert and resets stale input state.
    private func openQuickAdd() {
        quickAddName = ""
        quickAddValidationText = ""
        showsQuickAddAlert = true
    }

    /// Resets quick-add text and validation values.
    private func resetQuickAddState() {
        quickAddName = ""
        quickAddValidationText = ""
    }

    /// Creates one client from quick-add input and navigates to details.
    private func createQuickClient() {
        let normalizedName = quickAddName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedName.isEmpty == false else {
            quickAddValidationText = ValidationError.clientNameRequired.localizedDescription
            showsQuickAddValidationAlert = true
            return
        }

        do {
            let client = try ClientManager.createQuick(name: normalizedName, in: viewContext)
            createdClient = client
            resetQuickAddState()
        } catch {
            quickAddValidationText = error.localizedDescription
            showsQuickAddValidationAlert = true
        }
    }
}
