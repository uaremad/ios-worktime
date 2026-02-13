//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Renders billing default settings in a dedicated screen.
@MainActor
struct BillingSettingsView: View {
    /// The managed object context used for persistence.
    @Environment(\.managedObjectContext) private var context

    /// The optional profile scope for configuration values.
    let profile: Profile? = nil

    /// Stores selected default currency.
    @State private var defaultCurrency: String = "EUR"

    /// Stores selected default tax mode.
    @State private var defaultTaxMode: TaxMode = .net

    /// Stores selected default jurisdiction.
    @State private var defaultJurisdiction: Jurisdiction = .europeanUnion

    /// Stores selected default payment terms.
    @State private var defaultPaymentTerms: PaymentTerms = .net14

    /// Stores default tax rate text value.
    @State private var defaultTaxRate: String = "0.0"

    /// Stores selected rounding mode.
    @State private var roundingMode: RoundingMode = .perLine

    /// Stores status message for alert presentation.
    @State private var statusMessage: String = ""

    /// Controls whether status alert is presented.
    @State private var showsStatusAlert: Bool = false

    /// Renders the dedicated billing settings UI.
    var body: some View {
        Form {
            Picker("Currency", selection: $defaultCurrency) {
                ForEach(["EUR", "USD", "GBP", "CHF"], id: \.self) { code in
                    Text(code).tag(code)
                }
            }

            Picker("Tax Mode", selection: $defaultTaxMode) {
                ForEach(TaxMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }

            Picker("Jurisdiction", selection: $defaultJurisdiction) {
                ForEach(Jurisdiction.allCases, id: \.self) { jurisdiction in
                    Text(jurisdiction.rawValue).tag(jurisdiction)
                }
            }

            Picker("Payment Terms", selection: $defaultPaymentTerms) {
                ForEach(PaymentTerms.allCases, id: \.self) { terms in
                    Text(terms.rawValue).tag(terms)
                }
            }

            #if os(iOS)
            TextField("Default Tax Rate", text: $defaultTaxRate)
                .keyboardType(.decimalPad)
            #else
            TextField("Default Tax Rate", text: $defaultTaxRate)
            #endif

            Picker("Rounding", selection: $roundingMode) {
                ForEach(RoundingMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }

            Button(L10n.generalSave) {
                save()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentColor)
        }
        .navigationTitle("Billing")
        .alert("Hinweis", isPresented: $showsStatusAlert) {
            Button(L10n.generalOk, role: .cancel) {}
        } message: {
            Text(statusMessage)
        }
        .onAppear {
            load()
        }
    }
}

private extension BillingSettingsView {
    /// Loads persisted billing defaults for the configured scope.
    func load() {
        defaultCurrency = readValue(.defaultCurrency) ?? "EUR"

        if let taxMode = TaxMode(rawValue: readValue(.defaultTaxMode) ?? TaxMode.net.rawValue) {
            defaultTaxMode = taxMode
        }

        if let jurisdiction = Jurisdiction(
            rawValue: readValue(.defaultJurisdiction) ?? Jurisdiction.europeanUnion.rawValue
        ) {
            defaultJurisdiction = jurisdiction
        }

        if let paymentTerms = PaymentTerms(rawValue: readValue(.defaultPaymentTerms) ?? PaymentTerms.net14.rawValue) {
            defaultPaymentTerms = paymentTerms
        }

        defaultTaxRate = readValue(.defaultTaxRate) ?? "0.0"

        if let mode = RoundingMode(rawValue: readValue(.defaultRoundingMode) ?? RoundingMode.perLine.rawValue) {
            roundingMode = mode
        }
    }

    /// Saves billing defaults for the configured scope.
    func save() {
        let normalizedTaxRate = defaultTaxRate.replacingOccurrences(of: ",", with: ".")
        guard Double(normalizedTaxRate) != nil else {
            statusMessage = "Default Tax Rate must be numeric."
            showsStatusAlert = true
            return
        }

        saveValue(defaultCurrency, for: .defaultCurrency)
        saveValue(defaultTaxMode.rawValue, for: .defaultTaxMode)
        saveValue(defaultJurisdiction.rawValue, for: .defaultJurisdiction)
        saveValue(defaultPaymentTerms.rawValue, for: .defaultPaymentTerms)
        saveValue(normalizedTaxRate, for: .defaultTaxRate)
        saveValue(roundingMode.rawValue, for: .defaultRoundingMode)

        statusMessage = "Billing defaults saved."
        showsStatusAlert = true
    }

    /// Reads a configuration value for one key and current scope.
    ///
    /// - Parameter key: The configuration key to resolve.
    /// - Returns: The resolved value or `nil` when unavailable.
    func readValue(_ key: ConfigurationKey) -> String? {
        do {
            return try ConfigurationStoreService.shared.value(
                for: key,
                profile: profile,
                context: context
            )
        } catch {
            return nil
        }
    }

    /// Saves one configuration value for one key and current scope.
    ///
    /// - Parameters:
    ///   - value: The value to persist.
    ///   - key: The configuration key to write.
    func saveValue(_ value: String?, for key: ConfigurationKey) {
        do {
            try ConfigurationStoreService.shared.setValue(
                value,
                for: key,
                profile: profile,
                context: context
            )
        } catch {
            statusMessage = "Could not save setting."
            showsStatusAlert = true
        }
    }
}
