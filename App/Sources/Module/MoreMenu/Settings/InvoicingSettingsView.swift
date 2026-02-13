//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Renders invoicing settings in a dedicated screen.
@MainActor
struct InvoicingSettingsView: View {
    /// The managed object context used for persistence.
    @Environment(\.managedObjectContext) private var context

    /// The optional profile scope for configuration values.
    let profile: Profile? = nil

    /// Defines available invoice sequence reset options.
    enum InvoiceSequenceResetRule: String, CaseIterable, Identifiable {
        /// Never resets sequence values.
        case never
        /// Resets sequence values every year.
        case yearly

        /// Returns stable identifier for picker rendering.
        var id: String { rawValue }

        /// Returns user-facing title.
        var title: String {
            switch self {
            case .never:
                "Never"
            case .yearly:
                "Yearly"
            }
        }
    }

    /// Stores invoice numbering prefix.
    @State private var invoicePrefix: String = "INV"

    /// Stores invoice numbering pattern.
    @State private var invoicePattern: String = "{YYYY}-{SEQ:000}"

    /// Stores next invoice sequence text.
    @State private var invoiceNextSequence: String = "1"

    /// Stores selected sequence reset rule.
    @State private var invoiceResetRule: InvoiceSequenceResetRule = .yearly

    /// Stores status message for alerts.
    @State private var statusMessage: String = ""

    /// Controls status alert presentation.
    @State private var showsStatusAlert: Bool = false

    /// Renders the dedicated invoicing settings UI.
    var body: some View {
        Form {
            TextField("Prefix", text: $invoicePrefix)
            TextField("Pattern", text: $invoicePattern)
            #if os(iOS)
            TextField("Next Sequence", text: $invoiceNextSequence)
                .keyboardType(.numberPad)
            #else
            TextField("Next Sequence", text: $invoiceNextSequence)
            #endif

            Picker("Reset Rule", selection: $invoiceResetRule) {
                ForEach(InvoiceSequenceResetRule.allCases) { rule in
                    Text(rule.title).tag(rule)
                }
            }

            Button(L10n.generalSave) {
                save()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentColor)
        }
        .navigationTitle("Invoicing")
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

private extension InvoicingSettingsView {
    /// Loads persisted invoicing values for current scope.
    func load() {
        invoicePrefix = readValue(.invoiceNumberPrefix) ?? "INV"
        invoicePattern = readValue(.invoiceNumberPattern) ?? "{YYYY}-{SEQ:000}"
        invoiceNextSequence = readValue(.invoiceNextSequence) ?? "1"

        if let rule = InvoiceSequenceResetRule(rawValue: readValue(.invoiceSequenceResetRule) ?? InvoiceSequenceResetRule.yearly.rawValue) {
            invoiceResetRule = rule
        }
    }

    /// Saves invoicing values for current scope.
    func save() {
        guard Int(invoiceNextSequence) != nil else {
            statusMessage = "Next sequence must be numeric."
            showsStatusAlert = true
            return
        }

        saveValue(invoicePrefix, for: .invoiceNumberPrefix)
        saveValue(invoicePattern, for: .invoiceNumberPattern)
        saveValue(invoiceNextSequence, for: .invoiceNextSequence)
        saveValue(invoiceResetRule.rawValue, for: .invoiceSequenceResetRule)

        statusMessage = "Invoicing settings saved."
        showsStatusAlert = true
    }

    /// Reads one configuration value for one key and current scope.
    ///
    /// - Parameter key: The configuration key to resolve.
    /// - Returns: The resolved value when available.
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
    ///   - key: The target configuration key.
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
