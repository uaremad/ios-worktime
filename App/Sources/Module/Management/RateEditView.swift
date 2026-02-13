//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Creates or edits one order-scoped rate.
@MainActor
struct RateEditView: View {
    /// The managed object context used for persistence.
    @Environment(\.managedObjectContext) private var viewContext

    /// Dismiss callback for this sheet.
    @Environment(\.dismiss) private var dismiss

    /// The selected order linked to this rate.
    let order: Order

    /// Optional existing rate in edit mode.
    let rate: Rates?

    /// Fetches optional activities for rate linkage.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) private var fetchedActivities: FetchedResults<Activities>

    /// The rate name input.
    @State private var name: String

    /// The selected billing type.
    @State private var billingType: BillingType

    /// The hourly-rate input value.
    @State private var hourlyRateText: String

    /// The fixed-amount input value.
    @State private var fixedAmountText: String

    /// The optional currency input value.
    @State private var currencyText: String

    /// Whether `valid_from` is enabled.
    @State private var hasValidFrom: Bool

    /// The selected `valid_from` date.
    @State private var validFrom: Date

    /// Whether `valid_to` is enabled.
    @State private var hasValidTo: Bool

    /// The selected `valid_to` date.
    @State private var validTo: Date

    /// Marks this rate as default.
    @State private var isDefault: Bool

    /// The selected optional activity.
    @State private var selectedActivity: Activities?

    /// Stores validation or save error messages.
    @State private var validationMessage: String = ""

    /// Controls validation alert presentation.
    @State private var showsValidationAlert = false

    /// Creates one rate edit view.
    ///
    /// - Parameters:
    ///   - order: The target order.
    ///   - rate: Optional existing rate.
    init(order: Order, rate: Rates? = nil) {
        self.order = order
        self.rate = rate
        _name = State(initialValue: rate?.name ?? "")
        _billingType = State(initialValue: BillingType(coreDataValue: rate?.billing_type) ?? .hourly)
        _hourlyRateText = State(initialValue: Self.decimalText(from: rate?.hourly_rate))
        _fixedAmountText = State(initialValue: Self.decimalText(from: rate?.fixed_amount))
        _currencyText = State(initialValue: rate?.currency ?? Self.defaultCurrencyCode())
        _hasValidFrom = State(initialValue: rate?.valid_from != nil)
        _validFrom = State(initialValue: rate?.valid_from ?? Date())
        _hasValidTo = State(initialValue: rate?.valid_to != nil)
        _validTo = State(initialValue: rate?.valid_to ?? Date())
        _isDefault = State(initialValue: rate?.is_default?.boolValue ?? false)
        _selectedActivity = State(initialValue: rate?.activity)
    }

    /// Renders the rate edit form.
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L10n.clientName, text: $name)
                        .textStyle(.body1)
                        .foregroundStyle(Color.aPrimary)

                    Picker("Billing", selection: $billingType) {
                        Text("hourly").tag(BillingType.hourly)
                        Text("fixed").tag(BillingType.fixed)
                        Text("none").tag(BillingType.none)
                    }
                    .pickerStyle(.segmented)

                    if billingType == .hourly {
                        TextField("hourly", text: $hourlyRateText)
                            .textStyle(.body1)
                            .foregroundStyle(Color.aPrimary)
                    }

                    if billingType == .fixed {
                        TextField("fixed", text: $fixedAmountText)
                            .textStyle(.body1)
                            .foregroundStyle(Color.aPrimary)
                    }

                    TextField("currency", text: $currencyText)
                        .textStyle(.body1)
                        .foregroundStyle(Color.aPrimary)

                    Picker(L10n.generalManagementActivities, selection: $selectedActivity) {
                        Text(L10n.generalNone).tag(Activities?.none)
                        ForEach(scopedActivities, id: \.objectID) { activity in
                            Text(normalized(activity.name))
                                .tag(activity as Activities?)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle(L10n.generalStatus, isOn: $isDefault)
                } header: {
                    Text(L10n.generalDetails)
                        .textStyle(.title3)
                        .accessibilityAddTraits(.isHeader)
                }
                .listRowBackground(Color.aListBackground)

                Section {
                    Toggle(L10n.exportDateRangeFrom, isOn: $hasValidFrom)
                    if hasValidFrom {
                        DatePicker(
                            L10n.exportDateRangeFrom,
                            selection: $validFrom,
                            displayedComponents: .date
                        )
                    }

                    Toggle(L10n.exportDateRangeTo, isOn: $hasValidTo)
                    if hasValidTo {
                        DatePicker(
                            L10n.exportDateRangeTo,
                            selection: $validTo,
                            displayedComponents: .date
                        )
                    }
                }
                .listRowBackground(Color.aListBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Color.aBackground)
            .navigationTitle(rate == nil ? L10n.generalSave : L10n.generalEdit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.generalCancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.generalSave) {
                        saveRate()
                    }
                }
            }
            .alert(L10n.generalDetails, isPresented: $showsValidationAlert) {
                Button(L10n.generalOk, role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    /// Returns activities visible for current profile scope.
    private var scopedActivities: [Activities] {
        let selectedProfile = order.profile ?? ManagementScopeResolver.selectedProfile(in: viewContext)
        return fetchedActivities.filter { activity in
            ManagementScopeResolver.isVisible(
                entityProfile: activity.profile,
                sharedProfileFlag: activity.shared_profile,
                selectedProfile: selectedProfile
            )
        }
    }

    /// Saves one rate via `RatesManager` and dismisses on success.
    private func saveRate() {
        let rateToSave = rate ?? Rates.insert(into: viewContext)
        rateToSave.order = order
        rateToSave.profile = order.profile
        rateToSave.name = normalizedOptional(name)
        rateToSave.billing_type = billingType.coreDataValue
        rateToSave.hourly_rate = decimalNumber(from: hourlyRateText)
        rateToSave.fixed_amount = decimalNumber(from: fixedAmountText)
        rateToSave.currency = normalizedOptional(currencyText)
        rateToSave.valid_from = hasValidFrom ? validFrom : nil
        rateToSave.valid_to = hasValidTo ? validTo : nil
        rateToSave.activity = selectedActivity
        rateToSave.is_default = NSNumber(value: isDefault)
        rateToSave.shared_profile = NSNumber(value: false)

        do {
            try RatesManager.save(rateToSave, in: viewContext)
            dismiss()
        } catch {
            viewContext.rollback()
            validationMessage = error.localizedDescription
            showsValidationAlert = true
        }
    }

    /// Converts one optional numeric value into text.
    ///
    /// - Parameter value: The source optional number.
    /// - Returns: Decimal text or empty string.
    private static func decimalText(from value: NSNumber?) -> String {
        guard let value else {
            return ""
        }
        return String(value.doubleValue)
    }

    /// Returns one locale-based default currency code.
    ///
    /// - Returns: The current locale currency identifier or an empty string.
    private static func defaultCurrencyCode() -> String {
        Locale.current.currency?.identifier ?? ""
    }

    /// Converts one decimal text value into `NSNumber`.
    ///
    /// - Parameter text: The source input string.
    /// - Returns: A parsed number or `nil`.
    private func decimalNumber(from text: String) -> NSNumber? {
        let normalizedText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard normalizedText.isEmpty == false, let value = Double(normalizedText) else {
            return nil
        }
        return NSNumber(value: value)
    }

    /// Returns one normalized fallback for optional values.
    ///
    /// - Parameter value: The optional source value.
    /// - Returns: A non-empty display value.
    private func normalized(_ value: String?) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.generalUnknown : trimmed
    }

    /// Returns one optional trimmed value for save operations.
    ///
    /// - Parameter value: The source text.
    /// - Returns: A trimmed optional value.
    private func normalizedOptional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
