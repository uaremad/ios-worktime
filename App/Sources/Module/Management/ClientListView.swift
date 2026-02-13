//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// View for listing and managing clients.
@MainActor
struct ClientListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default
    ) private var clients: FetchedResults<Client>

    @State private var searchText = ""
    @State private var showActiveOnly: Bool? = true
    @State private var showingAddSheet = false

    var filteredClients: [Client] {
        clients.filter { client in
            let matchesSearch = searchText.isEmpty ||
                (client.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (client.external_ref?.localizedCaseInsensitiveContains(searchText) ?? false)
            let matchesActive = showActiveOnly == nil || client.is_active?.boolValue == showActiveOnly
            return matchesSearch && matchesActive
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Status", selection: $showActiveOnly) {
                    Text(L10n.generalActive).tag(true)
                    Text(L10n.generalInactive).tag(false)
                    Text(L10n.generalAll).tag(nil as Bool?)
                }
                .pickerStyle(.segmented)
            }

            Section {
                ForEach(filteredClients, id: \.objectID) { client in
                    NavigationLink(destination: ClientDetailView(client: client)) {
                        ClientRowView(client: client)
                    }
                }
            }
        }
        .navigationTitle(L10n.generalManagementClients)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: L10n.generalPlaceholderSearchClients)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(L10n.accessibilityAddClient)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ClientEditView()
        }
    }
}
