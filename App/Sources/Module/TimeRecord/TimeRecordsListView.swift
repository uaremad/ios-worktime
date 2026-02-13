//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Displays time records grouped by day sections.
struct TimeRecordsListView: View {
    /// The managed object context used for fetch operations.
    @Environment(\.managedObjectContext) private var context

    /// The currently selected list filter.
    @State private var selectedFilter: NavigationStackRoute.TimeRecordsListFilter

    /// The fetched time records for the active filter.
    @State private var records: [TimeRecords] = []

    /// Creates a new time records list view.
    ///
    /// - Parameter initialFilter: The initial list filter.
    init(initialFilter: NavigationStackRoute.TimeRecordsListFilter = .all) {
        _selectedFilter = State(initialValue: initialFilter)
    }

    /// The list content grouped by day.
    var body: some View {
        List {
            ForEach(sectionDates, id: \.self) { sectionDate in
                Section(sectionTitle(for: sectionDate)) {
                    ForEach(records(for: sectionDate), id: \.objectID) { record in
                        rowView(record)
                    }
                }
            }

            if records.isEmpty {
                Text(L10n.generalOverviewRecentEmpty)
                    .textStyle(.body1)
                    .accessibilityLabel(L10n.generalOverviewRecentEmpty)
            }
        }
        .navigationTitle(L10n.generalOverviewActionOpenRecordsList)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                filterMenu
            }
        }
        .task {
            reloadRecords()
        }
        .task {
            await observeChanges()
        }
        .onChange(of: selectedFilter) { _, _ in
            reloadRecords()
        }
    }
}

private extension TimeRecordsListView {
    /// Returns all section dates sorted descending.
    var sectionDates: [Date] {
        let grouped = Dictionary(grouping: records) { sectionDate(for: $0) }
        return grouped.keys.sorted(by: >)
    }

    /// Returns one section date used for grouping.
    ///
    /// - Parameter record: The source record.
    /// - Returns: The normalized start of day date.
    func sectionDate(for record: TimeRecords) -> Date {
        let value = record.work_date ?? record.start_time ?? record.end_time ?? .now
        return Calendar.current.startOfDay(for: value)
    }

    /// Returns all records for one section date sorted by time descending.
    ///
    /// - Parameter daySectionDate: The section date.
    /// - Returns: The records in one day section.
    func records(for daySectionDate: Date) -> [TimeRecords] {
        records
            .filter { sectionDate(for: $0) == daySectionDate }
            .sorted {
                let left = $0.start_time ?? $0.created_at ?? .distantPast
                let right = $1.start_time ?? $1.created_at ?? .distantPast
                return left > right
            }
    }

    /// Builds one section title for a date.
    ///
    /// - Parameter date: The section date.
    /// - Returns: A localized section title.
    func sectionTitle(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return L10n.generalOverviewTodayTitle
        }
        return Self.sectionDateFormatter.string(from: date)
    }

    /// Builds one row for a time record.
    ///
    /// - Parameter record: The source record.
    /// - Returns: The rendered row.
    func rowView(_ record: TimeRecords) -> some View {
        VStack(alignment: .leading, spacing: .spacingXXS) {
            Text(normalizedValue(record.order?.name))
                .textStyle(.body2)

            Text(L10n.generalOverviewMetaLine(L10n.generalOverviewRunningActivity, normalizedValue(record.activity?.name)))
                .textStyle(.body3)

            Text(
                L10n.generalOverviewLatestTime(
                    shortTime(record.start_time),
                    shortTime(record.end_time)
                )
            )
            .textStyle(.body3)

            Text(
                L10n.generalOverviewMetaLine(
                    L10n.generalOverviewTodayNet,
                    durationLabel(for: Int(truncating: record.net_minutes ?? 0))
                )
            )
            .textStyle(.body3)
        }
        .padding(.vertical, .spacingXXS)
    }

    /// Builds the filter menu used in the toolbar.
    var filterMenu: some View {
        Menu {
            filterMenuButton(for: .all)
            filterMenuButton(for: .approvalPending)
            filterMenuButton(for: .billingOpen)
            filterMenuButton(for: .invoicedThisMonth)
        } label: {
            Label(selectedFilter.title, systemImage: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel(selectedFilter.title)
    }

    /// Builds one filter selection menu item.
    ///
    /// - Parameter filter: The represented filter value.
    /// - Returns: The menu button view.
    @ViewBuilder
    func filterMenuButton(for filter: NavigationStackRoute.TimeRecordsListFilter) -> some View {
        Button {
            selectedFilter = filter
        } label: {
            if filter == selectedFilter {
                Label(filter.title, systemImage: "checkmark")
            } else {
                Text(filter.title)
            }
        }
    }

    /// Observes context changes and refreshes the list on updates.
    func observeChanges() async {
        for await _ in NotificationCenter.default.notifications(
            named: .NSManagedObjectContextObjectsDidChange,
            object: context
        ) {
            reloadRecords()
        }
    }

    /// Loads records for the current filter and profile scope.
    func reloadRecords() {
        let request = TimeRecords.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "work_date", ascending: false),
            NSSortDescriptor(key: "start_time", ascending: false),
            NSSortDescriptor(key: "created_at", ascending: false)
        ]
        request.predicate = buildPredicate()

        do {
            records = try context.fetch(request)
        } catch {
            records = []
        }
    }

    /// Builds the fetch predicate for the selected filter and profile scope.
    ///
    /// - Returns: The combined predicate.
    func buildPredicate() -> NSPredicate? {
        let predicates: [NSPredicate?] = [
            profilePredicate(),
            filterPredicate()
        ]
        let valid = predicates.compactMap(\.self)
        guard valid.isEmpty == false else {
            return nil
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: valid)
    }

    /// Builds the filter predicate for the active list filter.
    ///
    /// - Returns: The optional filter predicate.
    func filterPredicate() -> NSPredicate? {
        switch selectedFilter {
        case .all:
            return nil
        case .approvalPending:
            return NSPredicate(format: "approval_status == %@", ApprovalStatus.submitted.coreDataValue)
        case .billingOpen:
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "billing_status == %@", BillingStatus.open.coreDataValue),
                NSPredicate(format: "(locked == NO) OR (locked == nil)")
            ])
        case .invoicedThisMonth:
            let calendar = Calendar.current
            let now = Date()
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: monthStart) ?? now
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "billing_status == %@", BillingStatus.invoiced.coreDataValue),
                NSPredicate(format: "invoiced_at >= %@ AND invoiced_at <= %@", monthStart as NSDate, monthEnd as NSDate)
            ])
        }
    }

    /// Builds the profile scope predicate from persisted active profile URI.
    ///
    /// - Returns: The optional profile predicate.
    func profilePredicate() -> NSPredicate? {
        let profileURI = SettingsStorageService.shared.activeProfileObjectURI
        guard profileURI.isEmpty == false,
              let objectURI = URL(string: profileURI),
              let coordinator = context.persistentStoreCoordinator,
              let objectID = coordinator.managedObjectID(forURIRepresentation: objectURI),
              let profile = try? context.existingObject(with: objectID) as? Profile
        else {
            return nil
        }
        return NSPredicate(format: "profile == %@", profile)
    }

    /// Builds one short localized time representation.
    ///
    /// - Parameter value: The optional source date.
    /// - Returns: The localized short time or fallback value.
    func shortTime(_ value: Date?) -> String {
        guard let value else {
            return L10n.generalOverviewValueUnknown
        }
        return Self.timeFormatter.string(from: value)
    }

    /// Builds one localized duration label from minutes.
    ///
    /// - Parameter minutes: The total minute amount.
    /// - Returns: A positional duration label.
    func durationLabel(for minutes: Int) -> String {
        Self.durationFormatter.string(from: TimeInterval(max(minutes, 0) * 60)) ?? "00:00"
    }

    /// Returns one normalized string with fallback.
    ///
    /// - Parameter value: The optional source value.
    /// - Returns: The normalized display value.
    func normalizedValue(_ value: String?) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.generalOverviewValueUnknown : trimmed
    }

    /// Stores the date formatter used for day section headers.
    static let sectionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Stores the date formatter used for row time values.
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// Stores the duration formatter used for net minute labels.
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }()
}

private extension NavigationStackRoute.TimeRecordsListFilter {
    /// Returns the localized title for one list filter.
    var title: String {
        switch self {
        case .all:
            L10n.generalOverviewActionOpenRecordsList
        case .approvalPending:
            L10n.generalOverviewOpenItemsApproval
        case .billingOpen:
            L10n.generalOverviewOpenItemsBilling
        case .invoicedThisMonth:
            L10n.generalOverviewOpenItemsInvoicedPeriod
        }
    }
}
