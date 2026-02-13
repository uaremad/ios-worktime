//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation
import Observation

/// Represents aggregated metrics for the current day.
struct OverviewTodayMetrics: Sendable {
    /// The summed net working minutes for the selected day.
    let netMinutes: Int

    /// The summed break minutes for the selected day.
    let breakMinutes: Int

    /// The number of matching time records for the selected day.
    let entryCount: Int

    /// The empty metrics value.
    static let zero = OverviewTodayMetrics(netMinutes: 0, breakMinutes: 0, entryCount: 0)
}

/// Represents workflow counters rendered in the open-items panel.
struct OverviewOpenItems: Sendable {
    /// The number of submitted records waiting for approval.
    let approvalPendingCount: Int

    /// The number of records still open for billing.
    let billingOpenCount: Int

    /// The number of records invoiced in the current month.
    let invoicedThisPeriodCount: Int

    /// The empty counters value.
    static let zero = OverviewOpenItems(approvalPendingCount: 0, billingOpenCount: 0, invoicedThisPeriodCount: 0)
}

/// Defines deep-link targets used by the open-items panel.
enum OverviewOpenItemsTarget: Sendable {
    /// Navigates to pending approval items.
    case approval

    /// Navigates to billing open items.
    case billing

    /// Navigates to this-period invoiced records.
    case invoiced
}

/// Loads and manages overview dashboard state.
@MainActor
@Observable
final class OverviewViewModel {
    /// The currently running record if available.
    var runningRecord: TimeRecords?

    /// The latest finished or active record shown in the summary card.
    var latestRecord: TimeRecords?

    /// The aggregated metrics for the current day.
    var todayMetrics: OverviewTodayMetrics = .zero

    /// The workflow counters shown in the open-items panel.
    var openItems: OverviewOpenItems = .zero

    /// The most recent records list.
    var recentRecords: [TimeRecords] = []

    /// The available active profiles used for profile scope selection.
    var availableProfiles: [Profile] = []

    /// Stores the selected profile object URI string.
    var selectedProfileObjectURI: String = "" {
        didSet {
            guard oldValue != selectedProfileObjectURI else {
                return
            }
            settingsStorage.activeProfileObjectURI = selectedProfileObjectURI
            reloadAll()
        }
    }

    /// Indicates whether profile selection should be visible.
    var isProfileSelectionVisible: Bool {
        availableProfiles.count > 1
    }

    /// The selected profile resolved from the persisted URI.
    var selectedProfile: Profile? {
        guard selectedProfileObjectURI.isEmpty == false else {
            return nil
        }
        return availableProfiles.first {
            $0.objectID.uriRepresentation().absoluteString == selectedProfileObjectURI
        }
    }

    /// The selected profile title used in the overview header.
    var selectedProfileTitle: String {
        selectedProfile?.name?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? L10n.generalOverviewProfileAll
    }

    /// The managed object context used by all dashboard queries.
    private let context: NSManagedObjectContext

    /// The persistent settings storage for profile scope.
    private let settingsStorage: SettingsStorageService

    /// Stores the running observation task for context changes.
    private var contextObservationTask: Task<Void, Never>?

    /// Creates a new overview view model.
    ///
    /// - Parameters:
    ///   - context: The Core Data context used for reads and writes.
    ///   - settingsStorage: Persistent key-value storage for active profile scope.
    init(
        context: NSManagedObjectContext,
        settingsStorage: SettingsStorageService = .shared
    ) {
        self.context = context
        self.settingsStorage = settingsStorage
        selectedProfileObjectURI = settingsStorage.activeProfileObjectURI
        reloadAll()
        observeContextChanges()
    }

    /// Reloads all overview sections from Core Data.
    func reloadAll() {
        availableProfiles = fetchActiveProfiles()
        selectedProfileObjectURI = normalizedSelectedProfileURI()
        runningRecord = fetchRunningRecord()
        latestRecord = fetchLatestRecord()
        todayMetrics = fetchTodayMetrics()
        openItems = fetchOpenItems()
        recentRecords = fetchRecentRecords(limit: 5)
    }

    /// Stores a new profile selection and refreshes the overview.
    ///
    /// - Parameter profileObjectURI: The selected profile URI string.
    func selectProfile(_ profileObjectURI: String) {
        selectedProfileObjectURI = profileObjectURI
    }

    /// Stops the current running record and persists the change.
    ///
    /// If no running record exists this method does nothing.
    func stopRunningRecord() {
        guard let runningRecord else {
            return
        }

        let now = Date()
        runningRecord.is_running = NSNumber(value: false)
        if runningRecord.end_time == nil {
            runningRecord.end_time = now
        }
        if runningRecord.duration_minutes == nil,
           let start = runningRecord.start_time,
           let end = runningRecord.end_time
        {
            let minutes = TimeRecordManager.durationMinutes(from: start, to: end)
            runningRecord.duration_minutes = NSNumber(value: minutes)
        }

        saveContextIfNeeded()
    }

    /// Persists an updated note on one record.
    ///
    /// - Parameters:
    ///   - record: The record to update.
    ///   - note: The note text to persist.
    func saveNote(for record: TimeRecords, note: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        record.notice = trimmed.isEmpty ? nil : trimmed
        saveContextIfNeeded()
    }

    /// Creates one duplicate record using the selected record as template.
    ///
    /// - Parameter record: The source record to duplicate.
    func duplicate(record: TimeRecords) {
        let duplicated = TimeRecords.insert(into: context)
        duplicated.created_at = Date()
        duplicated.work_date = record.work_date
        duplicated.start_time = record.start_time
        duplicated.end_time = record.end_time
        duplicated.duration_minutes = record.duration_minutes
        duplicated.break_minutes = record.break_minutes
        duplicated.net_minutes = record.net_minutes
        duplicated.notice = record.notice
        duplicated.order = record.order
        duplicated.activity = record.activity
        duplicated.costCentre = record.costCentre
        duplicated.rate = record.rate
        duplicated.profile = selectedProfile ?? record.profile
        duplicated.is_running = NSNumber(value: false)
        duplicated.locked = NSNumber(value: false)
        duplicated.approval_status = ApprovalStatus.draft.coreDataValue
        duplicated.billing_status = BillingStatus.open.coreDataValue
        saveContextIfNeeded()
    }

    /// Switches to the start tab.
    func openStartInput() {
        NavigationHub.tabSelection.selectedTab = .start
    }

    /// Switches to the values tab.
    func openRecordsList() {
        NavigationHub.tabSelection.selectedTab = .values
    }

    /// Opens one open-items destination.
    ///
    /// - Parameter target: The selected open-items KPI target.
    func openItemsDestination(_ target: OverviewOpenItemsTarget) {
        switch target {
        case .approval, .billing:
            NavigationHub.tabSelection.selectedTab = .values
        case .invoiced:
            NavigationHub.tabSelection.selectedTab = .report
        }
    }

    /// Returns a localized time string for one date value.
    ///
    /// - Parameter date: The date to format.
    /// - Returns: The localized short time string.
    func shortTime(for date: Date?) -> String {
        guard let date else {
            return L10n.generalOverviewValueUnknown
        }
        return Self.timeFormatter.string(from: date)
    }

    /// Returns a localized date-time string for one date value.
    ///
    /// - Parameter date: The date to format.
    /// - Returns: The localized short date-time string.
    func shortDateTime(for date: Date?) -> String {
        guard let date else {
            return L10n.generalOverviewValueUnknown
        }
        return Self.dateTimeFormatter.string(from: date)
    }

    /// Returns a localized hours-and-minutes duration from one minute amount.
    ///
    /// - Parameter minutes: The total number of minutes.
    /// - Returns: A formatted duration string.
    func durationLabel(for minutes: Int) -> String {
        Self.durationFormatter.string(from: TimeInterval(max(minutes, 0) * 60)) ?? "00:00"
    }
}

private extension OverviewViewModel {
    /// A localized formatter used for short time values.
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// A localized formatter used for short date-time values.
    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    /// A localized formatter used for hour-minute durations.
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }()

    /// Starts listening for context change notifications to refresh overview content.
    func observeContextChanges() {
        contextObservationTask?.cancel()
        contextObservationTask = Task { [weak self, context] in
            for await _ in NotificationCenter.default.notifications(
                named: .NSManagedObjectContextObjectsDidChange,
                object: context
            ) {
                guard let self else {
                    return
                }
                reloadAll()
            }
        }
    }

    /// Fetches active profiles sorted by name.
    ///
    /// - Returns: The active profiles list.
    func fetchActiveProfiles() -> [Profile] {
        let request = Profile.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        request.predicate = NSPredicate(format: "(is_active == nil) OR (is_active == YES)")
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }

    /// Returns one normalized selected profile URI value.
    ///
    /// - Returns: A valid selected URI or an empty string for shared scope.
    func normalizedSelectedProfileURI() -> String {
        guard availableProfiles.isEmpty == false else {
            return ""
        }

        if selectedProfileObjectURI.isEmpty,
           let first = availableProfiles.first
        {
            return first.objectID.uriRepresentation().absoluteString
        }

        if availableProfiles.contains(where: { $0.objectID.uriRepresentation().absoluteString == selectedProfileObjectURI }) {
            return selectedProfileObjectURI
        }

        return availableProfiles.first?.objectID.uriRepresentation().absoluteString ?? ""
    }

    /// Returns the shared base predicate for profile scope.
    ///
    /// - Returns: The profile filter predicate for queries.
    func profilePredicate() -> NSPredicate? {
        guard let selectedProfile else {
            return nil
        }
        return NSPredicate(format: "profile == %@", selectedProfile)
    }

    /// Fetches at most one running record.
    ///
    /// - Returns: The running record when available.
    func fetchRunningRecord() -> TimeRecords? {
        let request = TimeRecords.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [
            NSSortDescriptor(key: "start_time", ascending: false),
            NSSortDescriptor(key: "created_at", ascending: false)
        ]
        request.predicate = compoundPredicate([
            NSPredicate(format: "is_running == YES"),
            profilePredicate()
        ])
        do {
            return try context.fetch(request).first
        } catch {
            return nil
        }
    }

    /// Fetches the latest record in scope.
    ///
    /// - Returns: The latest record when available.
    func fetchLatestRecord() -> TimeRecords? {
        let request = TimeRecords.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [
            NSSortDescriptor(key: "start_time", ascending: false),
            NSSortDescriptor(key: "created_at", ascending: false)
        ]
        request.predicate = profilePredicate()
        do {
            return try context.fetch(request).first
        } catch {
            return nil
        }
    }

    /// Fetches today's aggregated metrics in scope.
    ///
    /// - Returns: The aggregated today metrics.
    func fetchTodayMetrics() -> OverviewTodayMetrics {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return .zero
        }

        let request = TimeRecords.fetchRequest()
        request.predicate = compoundPredicate([
            NSPredicate(format: "work_date >= %@ AND work_date < %@", startOfDay as NSDate, endOfDay as NSDate),
            profilePredicate()
        ])

        do {
            let records = try context.fetch(request)
            let netMinutes = records.reduce(0) { partialResult, record in
                partialResult + Int(truncating: record.net_minutes ?? 0)
            }
            let breakMinutes = records.reduce(0) { partialResult, record in
                partialResult + Int(truncating: record.break_minutes ?? 0)
            }
            return OverviewTodayMetrics(
                netMinutes: netMinutes,
                breakMinutes: breakMinutes,
                entryCount: records.count
            )
        } catch {
            return .zero
        }
    }

    /// Fetches open-items counters in scope.
    ///
    /// - Returns: All open-items counters.
    func fetchOpenItems() -> OverviewOpenItems {
        let profile = profilePredicate()
        let approval = count(for: compoundPredicate([
            NSPredicate(format: "approval_status == %@", ApprovalStatus.submitted.coreDataValue),
            profile
        ]))

        let billing = count(for: compoundPredicate([
            NSPredicate(format: "billing_status == %@", BillingStatus.open.coreDataValue),
            NSPredicate(format: "(locked == NO) OR (locked == nil)"),
            profile
        ]))

        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: startOfMonth) ?? Date()

        let invoiced = count(for: compoundPredicate([
            NSPredicate(format: "billing_status == %@", BillingStatus.invoiced.coreDataValue),
            NSPredicate(format: "invoiced_at >= %@ AND invoiced_at <= %@", startOfMonth as NSDate, endOfMonth as NSDate),
            profile
        ]))

        return OverviewOpenItems(
            approvalPendingCount: approval,
            billingOpenCount: billing,
            invoicedThisPeriodCount: invoiced
        )
    }

    /// Fetches recent records in scope.
    ///
    /// - Parameter limit: The maximum number of records to fetch.
    /// - Returns: The recent records list.
    func fetchRecentRecords(limit: Int) -> [TimeRecords] {
        let request = TimeRecords.fetchRequest()
        request.fetchLimit = limit
        request.sortDescriptors = [
            NSSortDescriptor(key: "start_time", ascending: false),
            NSSortDescriptor(key: "created_at", ascending: false)
        ]
        request.predicate = profilePredicate()
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }

    /// Returns the count for one predicate in the time records entity.
    ///
    /// - Parameter predicate: The predicate used for counting.
    /// - Returns: The number of matching records.
    func count(for predicate: NSPredicate?) -> Int {
        let request = TimeRecords.fetchRequest()
        request.includesSubentities = false
        request.predicate = predicate
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }

    /// Creates one compound predicate from optional inputs.
    ///
    /// - Parameter predicates: Optional predicates that should be combined.
    /// - Returns: One combined predicate or nil.
    func compoundPredicate(_ predicates: [NSPredicate?]) -> NSPredicate? {
        let validPredicates = predicates.compactMap(\.self)
        guard validPredicates.isEmpty == false else {
            return nil
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: validPredicates)
    }

    /// Persists pending context changes and refreshes the dashboard.
    func saveContextIfNeeded() {
        guard context.hasChanges else {
            reloadAll()
            return
        }

        do {
            try context.save()
        } catch {
            context.rollback()
        }
        reloadAll()
    }
}

private extension String {
    /// Returns nil when the string is empty after trimming whitespaces.
    var nonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
