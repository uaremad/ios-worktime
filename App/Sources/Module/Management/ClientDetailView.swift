//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

/// Central client hub view with entry points for orders, rates, and client info.
@MainActor
struct ClientDetailView: View {
    /// The selected client represented by this detail screen.
    let client: Client

    /// Renders the client detail body.
    var body: some View {
        List {
            Section {
                LabeledContent(L10n.clientName, value: displayName)
                LabeledContent(L10n.generalStatus, value: displayStatus)
            } header: {
                Text(L10n.generalDetails)
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)
            }
            .listRowBackground(Color.aListBackground)

            Section {
                NavigationLink(destination: ClientOrdersListView(client: client)) {
                    Label(L10n.generalManagementOrders, systemImage: "doc.text")
                        .textStyle(.body1)
                }

                NavigationLink(destination: ClientRatesEntryView(client: client)) {
                    Label(L10n.generalManagementRates, systemImage: "dollarsign.circle")
                        .textStyle(.body1)
                }

                NavigationLink(destination: ClientInfoView(client: client)) {
                    Label(L10n.generalDetails, systemImage: "person.text.rectangle")
                        .textStyle(.body1)
                }
            }
            .listRowBackground(Color.aListBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.aBackground)
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension ClientDetailView {
    /// Returns one non-empty client name for title and metadata.
    var displayName: String {
        let trimmed = client.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.generalUnknown : trimmed
    }

    /// Returns the localized active-state text.
    var displayStatus: String {
        (client.is_active?.boolValue ?? true) ? L10n.generalActive : L10n.generalInactive
    }
}
