//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

/// Displays client master data and provides an edit entry point.
@MainActor
struct ClientInfoView: View {
    /// The client displayed in this info screen.
    let client: Client

    /// Controls edit-sheet presentation.
    @State private var showsEditSheet = false

    /// Renders the client info body.
    var body: some View {
        List {
            Section {
                infoRow(title: L10n.clientName, value: normalized(client.name))
                infoRow(title: L10n.clientExternalRef, value: normalized(client.external_ref))
                infoRow(title: L10n.clientEmail, value: normalized(client.email))
                infoRow(title: L10n.clientAddress, value: normalized(client.address))
            } header: {
                Text(L10n.generalDetails)
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)
            }
            .listRowBackground(Color.aListBackground)

            Section {
                infoRow(title: L10n.clientInvoiceEmail, value: normalized(client.invoice_email))
                infoRow(title: L10n.clientInvoiceAddress, value: normalized(client.invoice_address))
                infoRow(title: L10n.clientCountryCode, value: normalized(client.country_code))
                infoRow(title: L10n.clientTaxId, value: normalized(client.tax_id))
                infoRow(title: L10n.clientVatId, value: normalized(client.vat_id))
                infoRow(title: L10n.clientSalesTaxId, value: normalized(client.sales_tax_id))
                infoRow(
                    title: L10n.clientSalesTaxExempt,
                    value: displayBool(client.sales_tax_exempt?.boolValue ?? false)
                )
            } header: {
                Text(L10n.clientInvoiceDetails)
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)
            }
            .listRowBackground(Color.aListBackground)

            Section {
                infoRow(
                    title: L10n.generalStatus,
                    value: (client.is_active?.boolValue ?? true) ? L10n.generalActive : L10n.generalInactive
                )
                infoRow(
                    title: L10n.clientSharedProfile,
                    value: displayBool(client.shared_profile?.boolValue ?? true)
                )
            }
            .listRowBackground(Color.aListBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.aBackground)
        .navigationTitle(normalized(client.name))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(L10n.generalEdit) {
                    showsEditSheet = true
                }
                .accessibilityLabel(L10n.accessibilityEditClient)
            }
        }
        .sheet(isPresented: $showsEditSheet) {
            ClientEditView(client: client)
        }
    }

    /// Renders one title-value row.
    ///
    /// - Parameters:
    ///   - title: The field label.
    ///   - value: The field value.
    /// - Returns: One row view.
    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacingS) {
            Text(title)
                .textStyle(.body1)
                .foregroundStyle(Color.aPrimary)
            Spacer(minLength: .spacingS)
            Text(value)
                .textStyle(.body3)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    /// Returns one normalized fallback for optional string values.
    ///
    /// - Parameter value: The optional source text.
    /// - Returns: A non-empty display value.
    private func normalized(_ value: String?) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.generalUnknown : trimmed
    }

    /// Returns a localized bool display string.
    ///
    /// - Parameter value: The source bool value.
    /// - Returns: `generalActive` for `true`, `generalInactive` for `false`.
    private func displayBool(_ value: Bool) -> String {
        value ? L10n.generalActive : L10n.generalInactive
    }
}
