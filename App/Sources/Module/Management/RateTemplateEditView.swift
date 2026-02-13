//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Creates or edits one reusable rate template.
@MainActor
struct RateTemplateEditView: View {
    /// The managed object context used for persistence.
    @Environment(\.managedObjectContext) private var viewContext

    /// Dismiss callback used by the sheet.
    @Environment(\.dismiss) private var dismiss

    /// The optional template for edit mode.
    let template: RateTemplate?

    /// The template name field.
    @State private var name: String

    /// The selected billing type.
    @State private var billingType: BillingType

    /// The hourly rate input field.
    @State private var hourlyRateText: String

    /// The fixed amount input field.
    @State private var fixedAmountText: String

    /// The optional currency field.
    @State private var currencyText: String

    /// Indicates whether a valid_from date should be stored.
    @State private var hasValidFrom: Bool

    /// The selected valid_from date.
    @State private var validFromDate: Date

    /// Indicates whether a valid_to date should be stored.
    @State private var hasValidTo: Bool

    /// The selected valid_to date.
    @State private var validToDate: Date

    /// Indicates whether the template is active.
    @State private var isActive: Bool

    /// Indicates whether the template is shared.
    @State private var isSharedProfile: Bool

    /// The selected optional activity.
    @State private var selectedActivity: Activities?

    /// Stores a human-readable validation message.
    @State private var validationMessage: String = ""

    /// Controls validation alert presentation.
    @State private var showsValidationAlert = false

    /// Fetches active activities for optional linking.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
        predicate: NSPredicate(format: "(is_active == nil) OR (is_active == YES)")
    ) private var availableActivities: FetchedResults<Activities>

    /// Creates one edit view in create or edit mode.
    ///
    /// - Parameter template: The template to edit or `nil` for create mode.
    init(template: RateTemplate? = nil) {
        self.template = template
        _name = State(initialValue: template?.name ?? "")
        _billingType = State(initialValue: BillingType(coreDataValue: template?.billing_type) ?? .hourly)
        _hourlyRateText = State(initialValue: Self.toText(template?.hourly_rate))
        _fixedAmountText = State(initialValue: Self.toText(template?.fixed_amount))
        _currencyText = State(initialValue: template?.currency ?? Self.defaultCurrencyCode())
        _hasValidFrom = State(initialValue: template?.valid_from != nil)
        _validFromDate = State(initialValue: template?.valid_from ?? Date())
        _hasValidTo = State(initialValue: template?.valid_to != nil)
        _validToDate = State(initialValue: template?.valid_to ?? Date())
        _isActive = State(initialValue: template?.is_active?.boolValue ?? true)
        _isSharedProfile = State(initialValue: template?.shared_profile?.boolValue ?? true)
        _selectedActivity = State(initialValue: template?.activity)
    }

    /// Renders the edit form.
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textStyle(.body1)
                        .foregroundStyle(Color.aPrimary)

                    Picker("Billing Type", selection: $billingType) {
                        Text("Hourly").tag(BillingType.hourly)
                        Text("Fixed").tag(BillingType.fixed)
                        Text("None").tag(BillingType.none)
                    }
                    .pickerStyle(.segmented)

                    if billingType == .hourly {
                        TextField("Hourly Rate", text: $hourlyRateText)
                            .textStyle(.body1)
                            .foregroundStyle(Color.aPrimary)
                    }

                    if billingType == .fixed {
                        TextField("Fixed Amount", text: $fixedAmountText)
                            .textStyle(.body1)
                            .foregroundStyle(Color.aPrimary)
                    }

                    TextField("Currency", text: $currencyText)
                        .textStyle(.body1)
                        .foregroundStyle(Color.aPrimary)

                    Picker("Activity", selection: $selectedActivity) {
                        Text(L10n.generalNone).tag(Activities?.none)
                        ForEach(availableActivities, id: \.objectID) { activity in
                            Text(normalizedName(activity.name))
                                .tag(activity as Activities?)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("Active", isOn: $isActive)
                    Toggle("Shared", isOn: $isSharedProfile)
                } header: {
                    Text(L10n.generalDetails)
                        .textStyle(.title3)
                        .accessibilityAddTraits(.isHeader)
                }
                .listRowBackground(Color.aListBackground)

                Section {
                    Toggle("Valid From", isOn: $hasValidFrom)
                    if hasValidFrom {
                        DatePicker("From", selection: $validFromDate, displayedComponents: .date)
                    }
                    Toggle("Valid To", isOn: $hasValidTo)
                    if hasValidTo {
                        DatePicker("To", selection: $validToDate, displayedComponents: .date)
                    }
                } header: {
                    Text("Validity")
                        .textStyle(.title3)
                        .accessibilityAddTraits(.isHeader)
                }
                .listRowBackground(Color.aListBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Color.aBackground)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.generalCancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.generalSave) {
                        save()
                    }
                }
            }
            .alert("Validation", isPresented: $showsValidationAlert) {
                Button(L10n.generalOk, role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }
}

private extension RateTemplateEditView {
    /// Converts an optional `NSNumber` into a decimal text field value.
    ///
    /// - Parameter value: The optional numeric value.
    /// - Returns: A formatted text value or empty string.
    static func toText(_ value: NSNumber?) -> String {
        guard let value else { return "" }
        return String(value.doubleValue)
    }

    /// Returns one locale-based default currency code.
    ///
    /// - Returns: The current locale currency identifier or an empty string.
    static func defaultCurrencyCode() -> String {
        Locale.current.currency?.identifier ?? ""
    }

    /// Parses one optional decimal value from user input.
    ///
    /// - Parameter text: The decimal text field value.
    /// - Returns: The parsed value or `nil` for empty/invalid input.
    func parseDecimal(_ text: String) -> NSNumber? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized) else { return nil }
        return NSNumber(value: value)
    }

    /// Persists template changes with validation.
    func save() {
        let templateToSave = template ?? RateTemplate.insert(into: viewContext)
        templateToSave.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        templateToSave.billing_type = billingType.coreDataValue
        templateToSave.hourly_rate = parseDecimal(hourlyRateText)
        templateToSave.fixed_amount = parseDecimal(fixedAmountText)
        let normalizedCurrency = currencyText.trimmingCharacters(in: .whitespacesAndNewlines)
        templateToSave.currency = normalizedCurrency.isEmpty ? nil : normalizedCurrency
        templateToSave.valid_from = hasValidFrom ? validFromDate : nil
        templateToSave.valid_to = hasValidTo ? validToDate : nil
        templateToSave.is_active = NSNumber(value: isActive)
        templateToSave.shared_profile = NSNumber(value: isSharedProfile)
        templateToSave.activity = selectedActivity

        do {
            try RateTemplateManager.saveTemplate(templateToSave, in: viewContext)
            dismiss()
        } catch {
            viewContext.rollback()
            validationMessage = error.localizedDescription
            showsValidationAlert = true
        }
    }

    /// Returns a non-empty text fallback for optional name values.
    ///
    /// - Parameter value: The optional name value.
    /// - Returns: The trimmed value or `generalUnknown`.
    func normalizedName(_ value: String?) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.generalUnknown : trimmed
    }
}
