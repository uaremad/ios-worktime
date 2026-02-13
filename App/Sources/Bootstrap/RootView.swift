//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Observation
import SwiftUI

/// The root view of the WorktimeApp application.
struct RootView: View {
    /// The currently selected tab in the root tab bar.
    @State var selectedTab: TabItem.Tab = .start

    #if os(macOS)
    /// The currently selected sidebar item on macOS.
    @State var selectedSidebarItem: RootSidebarItem = .overview

    /// Controls presentation of the measurement input sheet on macOS.
    @State var showsMeasurementSheet: Bool = false

    /// The active macOS detail flow bound to the split detail navigation stack.
    @State var macNavigationFlow: NavigationStackFlow = NavigationHub.summaryFlow

    /// The shared settings storage for persisted selections.
    let settingsStorage: SettingsStorageService = .shared
    #endif

    /// The managed object context for Core Data operations.
    @Environment(\.managedObjectContext) var viewContext

    /// Stores the cached singular counterparty label for fast tab-title rendering.
    @AppStorage("SharedCounterpartyLabelSingular")
    private var sharedCounterpartyLabelSingular: String = ""

    /// The body of the root view.
    var body: some View {
        Group {
            #if os(macOS)
            macOSRootView
            #else
            iOSRootView
            #endif
        }
        .appThemeColors()
        .onAppear {
            selectedTab = NavigationHub.tabSelection.selectedTab
        }
        .onChange(of: selectedTab) { _, newValue in
            NavigationHub.tabSelection.selectedTab = newValue
        }
        .onChange(of: NavigationHub.tabSelection.selectedTab) { _, newValue in
            guard selectedTab != newValue else {
                return
            }
            selectedTab = newValue
        }
    }

    /// Initializes a new root view with the specified tab.
    ///
    /// - Parameter tab: The tab item to be initially selected.
    init(tab: TabItem.Tab = .start) {
        _selectedTab = State(initialValue: tab)
        #if os(macOS)
        let initialItem = RootSidebarItem.defaultSelection(
            tab: tab,
            settingsStorage: SettingsStorageService.shared
        )
        _selectedSidebarItem = State(initialValue: initialItem)
        _macNavigationFlow = State(initialValue: RootSidebarItem.navigationFlow(for: initialItem))
        #endif
    }

    /// Resolves the dynamic title for the values tab on iOS.
    var valuesTabTitle: String {
        let configuredTitle = sharedCounterpartyLabelSingular.trimmingCharacters(in: .whitespacesAndNewlines)
        guard configuredTitle.isEmpty == false
        else {
            return L10n.generalTabManagement
        }
        return configuredTitle
    }
}

/// A container that binds a dedicated navigation flow to a tab.
struct TabNavigationContainer<Content: View>: View {
    /// The navigation flow that owns the path for this tab.
    @Bindable var flow: NavigationStackFlow

    /// The content rendered inside the navigation stack.
    private let content: Content

    /// Creates a container for a tab-specific navigation flow.
    /// - Parameters:
    ///   - flow: The navigation flow that backs this tab.
    ///   - content: The content displayed within the navigation stack.
    init(flow: NavigationStackFlow, @ViewBuilder content: () -> Content) {
        self.flow = flow
        self.content = content()
    }

    /// The body of the navigation container view.
    var body: some View {
        NavigationStack(path: $flow.path) {
            content
                .navigationDestination(for: NavigationStackRoute.self) { route in
                    NavigationDestinations(route: route)
                }
        }
        .appThemeColors()
    }
}

/// Launches overview navigation automatically for the overview tab root.
struct OverviewRouteLauncher: View {
    /// The body of this launcher view.
    var body: some View {
        NavigationDestinations(route: .module(.overview))
    }
}

/// Launches reporting navigation automatically for the report tab root.
struct ReportRouteLauncher: View {
    /// The body of this launcher view.
    var body: some View {
        NavigationDestinations(route: .module(.reporting))
    }
}

/// A preview provider for the root view.
struct RootView_Previews: PreviewProvider {
    /// Generates previews of the root view.
    static var previews: some View {
        RootView()
    }
}
