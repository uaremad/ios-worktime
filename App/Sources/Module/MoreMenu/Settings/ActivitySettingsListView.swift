//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Lists and manages activity master data inside More settings.
@MainActor
struct ActivitySettingsListView: View {
    /// The Core Data context used for all activity operations.
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) private var fetchedActivities: FetchedResults<Activities>

    /// Controls presentation of the add-activity sheet.
    @State private var showsAddSheet = false

    /// Stores the currently edited activity for the edit sheet.
    @State private var selectedActivity: Activities?

    /// Renders the activity settings list.
    var body: some View {
        List {
            Section {
                ForEach(activeActivities, id: \.objectID) { activity in
                    activeRow(for: activity)
                }
                .listRowBackground(Color.aListBackground)
            } header: {
                Text(L10n.generalActive)
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)
            } footer: {
                Text("Tätigkeiten beschreiben, was du gemacht hast (z. B. Arbeit, Pause, Meeting).")
                    .textStyle(.body3)
                    .foregroundStyle(Color.secondary)
            }

            if inactiveActivities.isEmpty == false {
                Section {
                    ForEach(inactiveActivities, id: \.objectID) { activity in
                        inactiveRow(for: activity)
                    }
                    .listRowBackground(Color.aListBackground)
                } header: {
                    Text(L10n.generalInactive)
                        .textStyle(.title3)
                        .accessibilityAddTraits(.isHeader)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.aBackground)
        .navigationTitle(L10n.generalManagementActivities)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showsAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(L10n.generalManagementActivities)
            }
        }
        .sheet(isPresented: $showsAddSheet) {
            ActivitySettingsEditView()
            #if os(iOS)
                .presentationDetents([.height(220)])
            #else
                .presentationDetents([.medium])
            #endif
                .presentationBackground(Color.aBackground)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedActivity) { activity in
            ActivitySettingsEditView(activity: activity)
            #if os(iOS)
                .presentationDetents([.height(220)])
            #else
                .presentationDetents([.medium])
            #endif
                .presentationBackground(Color.aBackground)
                .presentationDragIndicator(.visible)
        }
    }

    /// Returns all activities sorted alphabetically by display name.
    private var sortedActivities: [Activities] {
        fetchedActivities.sorted { lhs, rhs in
            normalizedName(of: lhs).localizedCaseInsensitiveCompare(normalizedName(of: rhs)) == .orderedAscending
        }
    }

    /// Returns all active activities.
    private var activeActivities: [Activities] {
        sortedActivities.filter { $0.is_active?.boolValue ?? true }
    }

    /// Returns all inactive activities.
    private var inactiveActivities: [Activities] {
        sortedActivities.filter { ($0.is_active?.boolValue ?? true) == false }
    }

    /// Returns one normalized name for row sorting and display fallback.
    ///
    /// - Parameter activity: The activity that should be represented.
    /// - Returns: A non-empty display value.
    private func normalizedName(of activity: Activities) -> String {
        let trimmed = activity.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.generalUnknown : trimmed
    }

    /// Renders one active activity row with edit and swipe actions.
    ///
    /// - Parameter activity: The activity to display.
    /// - Returns: A row for one active activity.
    private func activeRow(for activity: Activities) -> some View {
        ActivitySettingsRowView(activity: activity)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedActivity = activity
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if isActivityInUse(activity) {
                    Button {
                        setActive(false, for: activity)
                    } label: {
                        Text(L10n.generalInactive)
                    }
                    .tint(.orange)
                } else {
                    Button(role: .destructive) {
                        delete(activity)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
    }

    /// Renders one inactive activity row with activation action.
    ///
    /// - Parameter activity: The activity to display.
    /// - Returns: A row for one inactive activity.
    private func inactiveRow(for activity: Activities) -> some View {
        ActivitySettingsRowView(activity: activity)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedActivity = activity
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    setActive(true, for: activity)
                } label: {
                    Text(L10n.generalActive)
                }
                .tint(.green)
            }
    }

    /// Indicates whether the activity is already referenced by business data.
    ///
    /// - Parameter activity: The activity that should be evaluated.
    /// - Returns: `true` when at least one relation already uses this activity.
    private func isActivityInUse(_ activity: Activities) -> Bool {
        let hasTimeRecords = activity.timerecords?.isEmpty == false
        let hasRates = activity.rates?.isEmpty == false
        let hasInvoiceLines = activity.invoiceLines?.isEmpty == false
        return hasTimeRecords || hasRates || hasInvoiceLines
    }

    /// Toggles one activity between active and inactive state.
    ///
    /// - Parameters:
    ///   - isActive: The target activity state.
    ///   - activity: The activity that should be updated.
    private func setActive(_ isActive: Bool, for activity: Activities) {
        activity.is_active = NSNumber(value: isActive)
        do {
            try viewContext.save()
        } catch {
            viewContext.rollback()
        }
    }

    /// Deletes one activity when it has no existing relations.
    ///
    /// - Parameter activity: The activity to delete.
    private func delete(_ activity: Activities) {
        guard isActivityInUse(activity) == false else {
            setActive(false, for: activity)
            return
        }
        viewContext.delete(activity)
        do {
            try viewContext.save()
        } catch {
            viewContext.rollback()
        }
    }
}

/// Renders one activity row for the activity settings list.
@MainActor
struct ActivitySettingsRowView: View {
    /// The represented activity.
    let activity: Activities

    /// Renders the row body.
    var body: some View {
        HStack(spacing: .spacingS) {
            Text(nameText)
                .textStyle(.body1)
                .foregroundStyle(Color.aPrimary)
            Spacer()
            if isFreeOfCharge {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
            }
            Text(usageCountDescription)
                .textStyle(.body3)
                .foregroundStyle(Color.secondary)
        }
        .padding(.vertical, 4)
    }

    /// Returns the normalized activity name.
    private var nameText: String {
        let trimmed = activity.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.generalUnknown : trimmed
    }

    /// Returns one compact usage indicator for this activity.
    private var usageCountDescription: String {
        let timeRecordsCount = activity.timerecords?.count ?? 0
        return L10n.generalListEntryCount(timeRecordsCount)
    }

    /// Indicates whether this activity currently has a default no-charge rate.
    private var isFreeOfCharge: Bool {
        let rates = activity.rates ?? []
        return rates.contains(where: { rate in
            guard let billingType = BillingType(coreDataValue: rate.billing_type) else {
                return false
            }
            return billingType == .none && (rate.is_default?.boolValue ?? false)
        })
    }
}
