//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation
import Observation

/// Manages add-time-record form state and user interaction logic.
@MainActor
@Observable
final class AddTimeRecordViewModel {
    /// Stores the selected work date.
    var workDate: Date = .now

    /// Stores the derived duration text in minutes.
    var durationMinutesText: String = ""

    /// Stores the selected start time.
    var startTime: Date = .now {
        didSet {
            updateDurationFromTimeRange()
        }
    }

    /// Stores the selected end time.
    var endTime: Date = .now {
        didSet {
            updateDurationFromTimeRange()
        }
    }

    /// Stores the selected activity.
    var selectedActivity: Activities?

    /// Stores the selected client.
    var selectedClient: Client? {
        didSet {
            handleClientSelectionChange()
        }
    }

    /// Stores the selected order.
    var selectedOrder: Order?

    /// Stores the order search query.
    var orderSearchQuery: String = ""

    /// Stores the optional description text.
    var descriptionText: String = ""

    /// Stores the fetched clients.
    private var clients: [Client] = []

    /// Stores the fetched orders.
    private var orders: [Order] = []

    /// Stores the fetched activities.
    private var activities: [Activities] = []

    /// Stores the Core Data context.
    private let context: NSManagedObjectContext

    /// Creates a new add-time-record view model.
    ///
    /// - Parameter context: The Core Data context used for reference data.
    init(context: NSManagedObjectContext) {
        self.context = context
        reloadReferenceData()
        refreshDurationFromTimeRange()
    }

    /// Refreshes derived duration text from the current start and end time values.
    func refreshDurationFromTimeRange() {
        updateDurationFromTimeRange()
    }

    /// Returns active clients sorted by display name.
    var availableClients: [Client] {
        clients
            .filter { $0.is_active?.boolValue ?? true }
            .sorted { clientDisplayName($0).localizedCaseInsensitiveCompare(clientDisplayName($1)) == .orderedAscending }
    }

    /// Returns active activities sorted by display name.
    var availableActivities: [Activities] {
        activities
            .filter { $0.is_active?.boolValue ?? true }
            .sorted { activityDisplayName($0).localizedCaseInsensitiveCompare(activityDisplayName($1)) == .orderedAscending }
    }

    /// Returns orders filtered by selected client and current query.
    var filteredOrders: [Order] {
        guard let selectedClient else {
            return []
        }
        let query = orderSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let clientObjectID = selectedClient.objectID
        let baseOrders = orders.filter {
            ($0.is_active?.boolValue ?? true) && $0.client?.objectID == clientObjectID
        }
        guard !query.isEmpty else {
            return baseOrders.sorted { orderDisplayName($0).localizedCaseInsensitiveCompare(orderDisplayName($1)) == .orderedAscending }
        }
        return baseOrders
            .filter { orderDisplayName($0).localizedCaseInsensitiveContains(query) }
            .sorted { orderDisplayName($0).localizedCaseInsensitiveCompare(orderDisplayName($1)) == .orderedAscending }
    }

    /// Returns recently used activities resolved from persisted names.
    var recentActivities: [Activities] {
        let names = recentActivityNames
        guard !names.isEmpty else {
            return []
        }
        var resolved: [Activities] = []
        for name in names {
            if let activity = availableActivities.first(where: { activityDisplayName($0) == name }) {
                resolved.append(activity)
            }
        }
        return resolved
    }

    /// Returns the client field title.
    var clientFieldTitle: String {
        guard let selectedClient else {
            return L10n.timerecordInputClientPlaceholder
        }
        return clientDisplayName(selectedClient)
    }

    /// Returns the activity field title.
    var activityFieldTitle: String {
        guard let selectedActivity else {
            return L10n.timerecordInputActivityPlaceholder
        }
        return activityDisplayName(selectedActivity)
    }

    /// Returns the order search placeholder depending on selected client.
    var orderSearchPlaceholder: String {
        if selectedClient == nil {
            return L10n.timerecordInputOrderSearchDisabled
        }
        return L10n.timerecordInputOrderSearchPlaceholder
    }

    /// Selects one client and resets order search scope.
    ///
    /// - Parameter client: The selected client.
    func selectClient(_ client: Client) {
        selectedClient = client
        orderSearchQuery = ""
        selectedOrder = nil
    }

    /// Clears the selected client and related order state.
    func clearClientSelection() {
        selectedClient = nil
        orderSearchQuery = ""
        selectedOrder = nil
    }

    /// Selects one order and copies its name into the search field.
    ///
    /// - Parameter order: The selected order.
    func selectOrder(_ order: Order) {
        selectedOrder = order
        orderSearchQuery = orderDisplayName(order)
    }

    /// Selects one activity and updates the recent activity cache.
    ///
    /// - Parameter activity: The selected activity.
    func selectActivity(_ activity: Activities) {
        selectedActivity = activity
        let selectedName = activityDisplayName(activity)
        var names = recentActivityNames.filter { $0 != selectedName }
        names.insert(selectedName, at: 0)
        recentActivityNames = Array(names.prefix(Self.maxRecentActivities))
    }

    /// Clears transient user input values without resetting selected client/activity.
    func clearTransientInputs() {
        descriptionText = ""
        orderSearchQuery = ""
        selectedOrder = nil
    }

    /// Returns the display name for one client.
    ///
    /// - Parameter client: The client to describe.
    /// - Returns: A non-empty display name.
    func clientDisplayName(_ client: Client) -> String {
        let name = client.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? L10n.timerecordInputUnknownValue : name
    }

    /// Returns the display name for one order.
    ///
    /// - Parameter order: The order to describe.
    /// - Returns: A non-empty display name.
    func orderDisplayName(_ order: Order) -> String {
        let name = order.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? L10n.timerecordInputUnknownValue : name
    }

    /// Returns the display name for one activity.
    ///
    /// - Parameter activity: The activity to describe.
    /// - Returns: A non-empty display name.
    func activityDisplayName(_ activity: Activities) -> String {
        let name = activity.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? L10n.timerecordInputUnknownValue : name
    }
}

private extension AddTimeRecordViewModel {
    /// Defines storage keys used by the view model.
    enum StorageKey {
        /// Stores recent activity names.
        static let recentActivityNames = "timerecord.activity.recent.names"
    }

    /// Defines view-model constants.
    enum Constants {
        /// Defines the maximum number of cached recent activities.
        static let maxRecentActivities = 3
    }

    /// Returns the maximum number of recent activities to keep.
    static var maxRecentActivities: Int {
        Constants.maxRecentActivities
    }

    /// Reads or writes the recent activity list from user defaults.
    var recentActivityNames: [String] {
        get {
            let rawValue = UserDefaults.standard.string(forKey: StorageKey.recentActivityNames) ?? ""
            return rawValue
                .split(separator: "|")
                .map { String($0) }
                .filter { !$0.isEmpty }
        }
        set {
            let compact = newValue
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            UserDefaults.standard.set(compact.joined(separator: "|"), forKey: StorageKey.recentActivityNames)
        }
    }

    /// Reloads client, order, and activity master data from Core Data.
    func reloadReferenceData() {
        clients = fetchEntities(using: Client.fetchRequest())
        orders = fetchEntities(using: Order.fetchRequest())
        activities = fetchEntities(using: Activities.fetchRequest())
    }

    /// Fetches one entity array using a typed request.
    ///
    /// - Parameter request: The fetch request to execute.
    /// - Returns: The fetched entities or an empty array when fetch fails.
    func fetchEntities<T: NSManagedObject>(using request: NSFetchRequest<T>) -> [T] {
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }

    /// Recalculates the duration text from start and end time.
    func updateDurationFromTimeRange() {
        let durationInMinutes = TimeRecordManager.durationMinutes(from: startTime, to: endTime)
        durationMinutesText = L10n.timerecordInputDurationMinutes(durationInMinutes)
    }

    /// Keeps selected order consistent when client selection changes.
    func handleClientSelectionChange() {
        guard let selectedOrder else {
            return
        }
        guard let selectedClient else {
            self.selectedOrder = nil
            return
        }
        if selectedOrder.client?.objectID != selectedClient.objectID {
            self.selectedOrder = nil
            orderSearchQuery = ""
        }
    }
}
