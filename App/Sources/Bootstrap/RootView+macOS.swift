//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

#if os(macOS)
extension RootView {
    /// Creates the macOS split view with sidebar navigation.
    var macOSRootView: some View {
        NavigationSplitView {
            VStack(spacing: .spacingS) {
                List {
                    ForEach(RootSidebarItem.sidebarItems) { item in
                        sidebarRow(for: item)
                    }
                }
                .listStyle(.sidebar)

                Button {
                    presentMeasurementSheet()
                } label: {
                    HStack {
                        Spacer()
                        Text(L10n.generalMeasurementAdd)
                            .textStyle(.button1)
                        Spacer()
                    }
                    .frame(minHeight: 46)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel(L10n.generalMeasurementAdd)
                .padding(.horizontal, .spacingS)
                .padding(.bottom, .spacingS)
            }
            .frame(minWidth: 240)
        } detail: {
            @Bindable var nav = macNavigationFlow

            NavigationStack(path: $nav.path) {
                macOSDetailRootContent
                    .navigationDestination(for: NavigationStackRoute.self) { route in
                        NavigationDestinations(route: route)
                    }
            }
            .appThemeColors()
        }
        .onAppear {
            syncFlow(with: selectedSidebarItem)
        }
        .onChange(of: selectedSidebarItem) { _, newValue in
            syncFlow(with: newValue)
        }
        .task {
            await observeMenuSelectionChanges()
        }
        .task {
            await observeMeasurementInputRequests()
        }
        .sheet(isPresented: $showsMeasurementSheet) {
            measurementSheetContent
        }
        .rootPeerSyncStatusAlerts()
    }

    /// Builds the measurement input sheet content for macOS.
    @ViewBuilder
    var measurementSheetContent: some View {
        MacMeasurementSheetView(isPresented: $showsMeasurementSheet)
    }

    /// Presents the measurement input sheet.
    func presentMeasurementSheet() {
        showsMeasurementSheet = true
    }

    /// Observes macOS menu selection notifications and updates sidebar selection.
    func observeMenuSelectionChanges() async {
        for await notification in NotificationCenter.default.notifications(named: MenuSelectionDidChangeNotification.name) {
            let postedNotification: Foundation.Notification = notification
            applyMenuSelection(from: postedNotification)
        }
    }

    /// Observes macOS menu requests for opening the measurement input.
    func observeMeasurementInputRequests() async {
        for await _ in NotificationCenter.default.notifications(named: MeasurementInputRequestedNotification.name) {
            presentMeasurementSheet()
        }
    }

    /// Applies one menu notification payload to the current sidebar selection.
    ///
    /// - Parameter notification: The posted menu selection notification.
    func applyMenuSelection(from notification: Foundation.Notification) {
        guard
            let rawSelection = notification.userInfo?["selection"] as? String,
            let menuSelection = MenuSelection(rawValue: rawSelection),
            let sidebarItem = sidebarItem(for: menuSelection)
        else {
            return
        }

        selectedSidebarItem = sidebarItem
    }

    /// Maps one menu selection to the corresponding sidebar entry.
    ///
    /// - Parameter selection: The incoming menu selection value.
    /// - Returns: The matching sidebar entry, or `nil` when unsupported.
    func sidebarItem(for selection: MenuSelection) -> RootSidebarItem? {
        switch selection {
        case .overview:
            .overview
        case .values:
            .values
        case .reportPie:
            .reportPie
        case .reportLine:
            .reportLine
        case .reportBar:
            .reportBar
        case .data:
            .data
        }
    }

    /// Synchronizes the active detail flow and persisted report index for one selection.
    ///
    /// - Parameter item: The selected sidebar item.
    func syncFlow(with item: RootSidebarItem) {
        macNavigationFlow = RootSidebarItem.navigationFlow(for: item)
        if let reportIndex = item.reportingTabIndex {
            settingsStorage.reportingSelectedTabIndex = reportIndex
        }
    }

    /// Resolves the currently active root content in the detail column.
    @ViewBuilder
    var macOSDetailRootContent: some View {
        switch selectedSidebarItem {
        case .overview:
            OverviewRouteLauncher()
        case .values:
            ManagementView()
        case .reportPie:
            ManagementView()
        case .reportLine:
            ManagementView()
        case .reportBar:
            ManagementView()
        case .data:
            ExportView(context: viewContext)
        case .export:
            MoreMenuView()
        }
    }

    /// Creates one sidebar row button.
    ///
    /// - Parameter item: The sidebar destination represented by the row.
    /// - Returns: A styled sidebar row.
    func sidebarRow(for item: RootSidebarItem) -> some View {
        let isSelected = selectedSidebarItem == item
        return SidebarButton(
            title: item.title,
            image: Image(systemName: item.systemImage),
            isSelected: isSelected,
            isFocused: false,
            action: {
                selectedSidebarItem = item
            }
        )
        .accessibilityLabel(item.title)
        .listRowBackground(Color.clear)
        .focusable(false)
        .focusEffectDisabled(true)
    }
}

/// Defines the sidebar navigation items used on macOS.
enum RootSidebarItem: String, CaseIterable, Identifiable {
    /// The overview entry.
    case overview
    /// The values list entry.
    case values
    /// The report summary (pie chart) entry.
    case reportPie
    /// The report trend (line chart) entry.
    case reportLine
    /// The report measurements (bar chart) entry.
    case reportBar
    /// The data tools entry.
    case data
    /// The export and settings entry.
    case export

    /// The stable identifier for the sidebar entry.
    var id: String { rawValue }

    /// The localized sidebar title.
    var title: String {
        switch self {
        case .overview:
            L10n.generalTabOverview
        case .values:
            L10n.generalTabOverview
        case .reportPie:
            L10n.generalTabOverview
        case .reportLine:
            L10n.generalTabOverview
        case .reportBar:
            L10n.generalTabOverview
        case .data:
            L10n.generalTabData
        case .export:
            L10n.generalTabExport
        }
    }

    /// The SF Symbol used for the sidebar entry.
    var systemImage: String {
        switch self {
        case .overview:
            TabItem.Tab.summary.icon()
        case .values:
            TabItem.Tab.values.icon()
        case .reportPie:
            "chart.pie"
        case .reportLine:
            "chart.xyaxis.line"
        case .reportBar:
            "chart.bar"
        case .data:
            "internaldrive"
        case .export:
            TabItem.Tab.export.icon()
        }
    }

    /// The report tab index used by the reporting view, if applicable.
    var reportingTabIndex: Int? {
        switch self {
        case .reportPie:
            0
        case .reportLine:
            1
        case .reportBar:
            2
        default:
            nil
        }
    }

    /// The ordered sidebar items displayed on macOS.
    static var sidebarItems: [RootSidebarItem] {
        [.overview, .values, .reportPie, .reportLine, .reportBar, .data]
    }

    /// Resolves the default selection for the provided tab.
    ///
    /// - Parameters:
    ///   - tab: The initial tab requested by the caller.
    ///   - settingsStorage: The shared settings storage for report selection.
    /// - Returns: The sidebar item that should be selected by default.
    static func defaultSelection(
        tab: TabItem.Tab,
        settingsStorage: SettingsStorageService
    ) -> RootSidebarItem {
        switch tab {
        case .summary:
            .overview
        case .values:
            .values
        case .report:
            reportItem(for: settingsStorage.reportingSelectedTabIndex)
        case .export:
            .data
        case .start, .bootstrap:
            .overview
        }
    }

    /// Resolves the persistent navigation flow mapped to one sidebar item.
    ///
    /// - Parameter item: The selected sidebar item.
    /// - Returns: The mapped persistent `NavigationStackFlow`.
    static func navigationFlow(for item: RootSidebarItem) -> NavigationStackFlow {
        switch item {
        case .overview:
            NavigationHub.summaryFlow
        case .values:
            NavigationHub.valuesFlow
        case .reportPie:
            NavigationHub.reportPieFlow
        case .reportLine:
            NavigationHub.reportLineFlow
        case .reportBar:
            NavigationHub.reportBarFlow
        case .data:
            NavigationHub.dataFlow
        case .export:
            NavigationHub.exportFlow
        }
    }

    /// Maps a reporting tab index to the matching sidebar item.
    ///
    /// - Parameter index: The reporting tab index.
    /// - Returns: The matching report sidebar item.
    static func reportItem(for index: Int) -> RootSidebarItem {
        switch index {
        case 1:
            .reportLine
        case 2:
            .reportBar
        default:
            .reportPie
        }
    }
}

/// Adds macOS sync status alerts for incoming peer-sync requests.
extension View {
    /// Attaches incoming sync status alerts to the root view.
    ///
    /// - Returns: The modified view with incoming sync status alerts.
    func rootPeerSyncStatusAlerts() -> some View {
        modifier(RootPeerSyncStatusAlertModifier())
    }
}

/// Displays sync start and completion alerts for incoming iOS-triggered sync.
private struct RootPeerSyncStatusAlertModifier: ViewModifier {
    /// The currently presented alert content.
    @State private var presentedAlert: IncomingSyncStatusAlert?

    /// Tracks peers for which an incoming sync has started.
    @State private var activeIncomingSyncPeerIds: Set<String> = []

    /// Builds the modified view hierarchy.
    ///
    /// - Parameter content: The wrapped root content.
    /// - Returns: The content with sync status alert handling attached.
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: LocalPeerSyncNotifications.syncActivityChanged)) { notification in
                handleSyncActivityChanged(notification: notification)
            }
            .alert(item: $presentedAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text(L10n.generalOk))
                )
            }
    }

    /// Handles one sync activity notification and presents incoming sync alerts.
    ///
    /// - Parameter notification: The posted sync activity notification.
    private func handleSyncActivityChanged(notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let peerId = userInfo[LocalPeerSyncNotifications.peerIdKey] as? String
        else {
            return
        }

        let isIncomingSyncRequest = (userInfo[LocalPeerSyncNotifications.isIncomingSyncRequestKey] as? Bool) ?? false
        guard isIncomingSyncRequest else {
            return
        }

        let deviceName = (userInfo[LocalPeerSyncNotifications.deviceNameKey] as? String) ?? ""
        let isSyncing = (userInfo[LocalPeerSyncNotifications.isSyncingKey] as? Bool) ?? false

        if isSyncing {
            activeIncomingSyncPeerIds.insert(peerId)
            presentedAlert = IncomingSyncStatusAlert(
                title: L10n.settingsPeerSyncIncomingSyncTitle,
                message: L10n.settingsPeerSyncSyncingHint(deviceName)
            )
            return
        }

        guard activeIncomingSyncPeerIds.remove(peerId) != nil else {
            return
        }
        presentedAlert = IncomingSyncStatusAlert(
            title: L10n.settingsPeerSyncStatusTitle,
            message: L10n.settingsPeerSyncStatusSyncedData
        )
    }
}

/// Represents one incoming sync status alert shown on macOS.
private struct IncomingSyncStatusAlert: Identifiable {
    /// Stable identifier for alert presentation.
    let id = UUID()

    /// The localized title displayed in the alert.
    let title: String

    /// The localized message displayed in the alert.
    let message: String
}

/// Provides a macOS sheet wrapper for the measurement input flow.
@MainActor
private struct MacMeasurementSheetView: View {
    /// Controls whether the sheet is presented.
    @Binding var isPresented: Bool

    /// Creates the measurement sheet view.
    ///
    /// - Parameters:
    ///   - isPresented: The binding controlling sheet presentation.
    init(isPresented: Binding<Bool>) {
        _isPresented = isPresented
    }

    /// The body of the measurement sheet view.
    var body: some View {
        AddTimeRecordView()
            .frame(minWidth: 960, minHeight: 540)
            .frame(idealWidth: 960, idealHeight: 540)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.generalCancel) {
                        isPresented = false
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel(L10n.generalCancel)
                }
            }
    }
}
#endif
