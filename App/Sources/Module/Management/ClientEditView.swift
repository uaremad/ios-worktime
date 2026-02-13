//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

/// View for creating or editing a client.
@MainActor
struct ClientEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let client: Client?

    @State private var name = ""
    @State private var externalRef = ""
    @State private var email = ""
    @State private var address = ""
    @State private var invoiceEmail = ""
    @State private var invoiceAddress = ""
    @State private var countryCode = ""
    @State private var taxId = ""
    @State private var vatId = ""
    @State private var salesTaxExempt = false
    @State private var salesTaxId = ""
    @State private var sharedProfile = false
    @State private var isActive = true

    init(client: Client? = nil) {
        self.client = client
        _name = State(initialValue: client?.name ?? "")
        _externalRef = State(initialValue: client?.external_ref ?? "")
        _email = State(initialValue: client?.email ?? "")
        _address = State(initialValue: client?.address ?? "")
        _invoiceEmail = State(initialValue: client?.invoice_email ?? "")
        _invoiceAddress = State(initialValue: client?.invoice_address ?? "")
        _countryCode = State(initialValue: client?.country_code ?? "")
        _taxId = State(initialValue: client?.tax_id ?? "")
        _vatId = State(initialValue: client?.vat_id ?? "")
        _salesTaxExempt = State(initialValue: client?.sales_tax_exempt?.boolValue ?? false)
        _salesTaxId = State(initialValue: client?.sales_tax_id ?? "")
        _sharedProfile = State(initialValue: client?.shared_profile?.boolValue ?? false)
        _isActive = State(initialValue: client?.is_active?.boolValue ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.generalDetails) {
                    TextField(L10n.clientName, text: $name)
                        .accessibilityLabel(L10n.clientName)
                    TextField(L10n.clientExternalRef, text: $externalRef)
                        .accessibilityLabel(L10n.clientExternalRef)
                    TextField(L10n.clientEmail, text: $email)
                        .accessibilityLabel(L10n.clientEmail)
                        .keyboardType(.emailAddress)
                    TextField(L10n.clientAddress, text: $address)
                        .accessibilityLabel(L10n.clientAddress)
                }

                Section(L10n.clientInvoiceDetails) {
                    TextField(L10n.clientInvoiceEmail, text: $invoiceEmail)
                        .accessibilityLabel(L10n.clientInvoiceEmail)
                        .keyboardType(.emailAddress)
                    TextField(L10n.clientInvoiceAddress, text: $invoiceAddress)
                        .accessibilityLabel(L10n.clientInvoiceAddress)
                    TextField(L10n.clientCountryCode, text: $countryCode)
                        .accessibilityLabel(L10n.clientCountryCode)
                    TextField(L10n.clientTaxId, text: $taxId)
                        .accessibilityLabel(L10n.clientTaxId)
                    TextField(L10n.clientVatId, text: $vatId)
                        .accessibilityLabel(L10n.clientVatId)
                    Toggle(L10n.clientSalesTaxExempt, isOn: $salesTaxExempt)
                        .accessibilityLabel(L10n.clientSalesTaxExempt)
                    if salesTaxExempt {
                        TextField(L10n.clientSalesTaxId, text: $salesTaxId)
                            .accessibilityLabel(L10n.clientSalesTaxId)
                    }
                }

                Section(L10n.generalAdditional) {
                    Toggle(L10n.clientSharedProfile, isOn: $sharedProfile)
                        .accessibilityLabel(L10n.clientSharedProfile)
                    Toggle(L10n.generalActive, isOn: $isActive)
                        .accessibilityLabel(L10n.generalActive)
                }
            }
            .navigationTitle(client == nil ? L10n.accessibilityAddClient : L10n.accessibilityEditClient)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.generalCancel) {
                        dismiss()
                    }
                    .accessibilityLabel(L10n.generalCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.generalSave) {
                        save()
                    }
                    .accessibilityLabel(L10n.generalSave)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let clientToSave = client ?? Client.insert(into: viewContext)
        clientToSave.name = name
        clientToSave.external_ref = externalRef.isEmpty ? nil : externalRef
        clientToSave.email = email.isEmpty ? nil : email
        clientToSave.address = address.isEmpty ? nil : address
        clientToSave.invoice_email = invoiceEmail.isEmpty ? nil : invoiceEmail
        clientToSave.invoice_address = invoiceAddress.isEmpty ? nil : invoiceAddress
        clientToSave.country_code = countryCode.isEmpty ? nil : countryCode
        clientToSave.tax_id = taxId.isEmpty ? nil : taxId
        clientToSave.vat_id = vatId.isEmpty ? nil : vatId
        clientToSave.sales_tax_exempt = NSNumber(value: salesTaxExempt)
        clientToSave.sales_tax_id = salesTaxId.isEmpty ? nil : salesTaxId
        clientToSave.shared_profile = NSNumber(value: sharedProfile)
        clientToSave.is_active = NSNumber(value: isActive)

        do {
            try ClientManager.save(clientToSave, in: viewContext)
            dismiss()
        } catch {
            viewContext.rollback()
        }
    }
}
