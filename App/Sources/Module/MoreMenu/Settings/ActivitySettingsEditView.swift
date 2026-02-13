//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Creates or edits one activity entity from the More settings module.
@MainActor
struct ActivitySettingsEditView: View {
    /// The Core Data context used for persistence.
    @Environment(\.managedObjectContext) private var viewContext

    /// Dismiss action for closing the sheet.
    @Environment(\.dismiss) private var dismiss

    /// The optional activity to edit. `nil` means create mode.
    let activity: Activities?

    /// The editable activity name field.
    @State private var name: String

    /// Controls presentation of duplicate-name validation alert.
    @State private var showsDuplicateNameAlert = false

    /// Stores whether the activity should be marked as free of charge.
    @State private var isFreeOfCharge = false

    /// Avoids repeatedly recalculating the toggle state on every appearance.
    @State private var hasLoadedFreeOfChargeState = false

    /// Creates the edit view with optional existing activity.
    ///
    /// - Parameter activity: The activity to edit or `nil` for create mode.
    init(activity: Activities? = nil) {
        self.activity = activity
        _name = State(initialValue: activity?.name ?? "")
    }

    /// Renders the edit sheet body.
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L10n.generalManagementActivities, text: $name)
                        .textStyle(.body1)
                        .foregroundStyle(Color.aPrimary)
                        .accessibilityLabel(L10n.generalManagementActivities)

                    Toggle(isOn: $isFreeOfCharge) {
                        Text("Unentgeltlich")
                            .textStyle(.body1)
                            .foregroundStyle(Color.aPrimary)
                    }
                    .tint(Color.accentColor)
                    .accessibilityLabel("Unentgeltlich")
                } header: {
                    Text(L10n.generalDetails)
                        .textStyle(.title3)
                        .accessibilityAddTraits(.isHeader)
                }
                .listRowBackground(Color.aListBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Color.aBackground)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        save()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityLabel(L10n.generalSave)
                }
            }
            .alert(L10n.generalAlreadyTaken, isPresented: $showsDuplicateNameAlert) {
                Button(L10n.generalOk, role: .cancel) {}
            } message: {
                Text(L10n.generalAlreadyTaken)
            }
            .onAppear {
                loadFreeOfChargeStateIfNeeded()
            }
        }
    }

    /// Returns one normalized field value.
    ///
    /// - Parameter value: The raw user-entered value.
    /// - Returns: The normalized value without leading or trailing spaces.
    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Indicates whether save can dismiss immediately without persistence.
    private var shouldDismissWithoutSaving: Bool {
        let trimmed = normalized(name)
        guard let activity else {
            return trimmed.isEmpty && isFreeOfCharge == false
        }
        return trimmed == normalized(activity.name ?? "") && isFreeOfCharge == hasDefaultNoneRate(for: activity)
    }

    /// Saves one activity after duplicate validation.
    private func save() {
        if shouldDismissWithoutSaving {
            dismiss()
            return
        }

        let trimmedName = normalized(name)
        guard trimmedName.isEmpty == false else {
            return
        }

        let request = Activities.fetchRequest()
        if let activity {
            request.predicate = NSPredicate(format: "name ==[c] %@ AND self != %@", trimmedName, activity)
        } else {
            request.predicate = NSPredicate(format: "name ==[c] %@", trimmedName)
        }
        request.fetchLimit = 1

        do {
            if try viewContext.fetch(request).isEmpty == false {
                showsDuplicateNameAlert = true
                return
            }
        } catch {
            viewContext.rollback()
            return
        }

        let activityToSave = activity ?? Activities.insert(into: viewContext)
        activityToSave.name = trimmedName
        activityToSave.is_active = NSNumber(value: true)
        activityToSave.shared_profile = NSNumber(value: false)

        do {
            try synchronizeFreeOfChargeFlag(for: activityToSave)
            if viewContext.hasChanges {
                try viewContext.save()
            }
            dismiss()
        } catch {
            viewContext.rollback()
        }
    }

    /// Loads the persisted free-of-charge toggle state once per sheet presentation.
    private func loadFreeOfChargeStateIfNeeded() {
        guard hasLoadedFreeOfChargeState == false else {
            return
        }
        hasLoadedFreeOfChargeState = true
        guard let activity else {
            isFreeOfCharge = false
            return
        }
        isFreeOfCharge = hasDefaultNoneRate(for: activity)
    }

    /// Indicates whether one default `none` rate is already linked to the activity.
    ///
    /// - Parameter activity: The activity to inspect.
    /// - Returns: `true` when at least one default no-charge rate exists.
    private func hasDefaultNoneRate(for activity: Activities) -> Bool {
        let request = Rates.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "activity == %@ AND billing_type == %@ AND is_default == YES",
            activity,
            BillingType.none.coreDataValue
        )

        do {
            return try viewContext.fetch(request).isEmpty == false
        } catch {
            return false
        }
    }

    /// Synchronizes the free-of-charge toggle with one default `none` rate.
    ///
    /// - Parameter activity: The activity that owns the no-charge setting.
    /// - Throws: Any Core Data save validation error.
    private func synchronizeFreeOfChargeFlag(for activity: Activities) throws {
        let request = Rates.fetchRequest()
        request.predicate = NSPredicate(
            format: "activity == %@ AND billing_type == %@",
            activity,
            BillingType.none.coreDataValue
        )

        let noneRates = try viewContext.fetch(request)

        if isFreeOfCharge {
            if let first = noneRates.first {
                first.is_default = NSNumber(value: true)
                first.activity = activity
                first.profile = activity.profile
                first.name = normalized(name)
            } else {
                let rate = Rates.insert(into: viewContext)
                rate.activity = activity
                rate.profile = activity.profile
                rate.name = normalized(name)
                rate.shared_profile = NSNumber(value: false)
                rate.billing_type = BillingType.none.coreDataValue
                rate.is_default = NSNumber(value: true)
                RatesManager.normalizeForSave(rate)
                try RatesManager.validateForSave(rate)
            }

            for duplicate in noneRates.dropFirst() {
                duplicate.is_default = NSNumber(value: false)
            }
        } else {
            for rate in noneRates {
                rate.is_default = NSNumber(value: false)
            }
        }
    }
}
