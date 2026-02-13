//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import Observation

/// Central hub managing all navigation flows across the app.
///
/// NavigationHub provides singleton instances of NavigationStackFlow for each major tab.
/// This ensures navigation state persists when switching between tabs - each tab maintains
/// its own navigation history.
///
/// ## Architecture
///
/// ```
/// NavigationHub (Static Singleton Manager)
///   ├─ summaryFlow: NavigationStackFlow
///   ├─ reportFlow: NavigationStackFlow
///   ├─ startFlow: NavigationStackFlow
///   ├─ valuesFlow: NavigationStackFlow
///   └─ exportFlow: NavigationStackFlow
/// ```
///
/// Each flow maintains independent navigation paths.
///
/// ## Usage
///
/// ```swift
/// // iOS - Each tab gets its own flow
/// TabContentView(flow: .values) { ValuesView() }
/// ```
/// Stores the currently selected tab across the application.
@Observable
public final class TabSelection {
    /// The currently selected tab.
    public var selectedTab: TabItem.Tab

    /// Creates a new tab selection with an initial tab.
    ///
    /// - Parameter selectedTab: The initial selected tab.
    public init(selectedTab: TabItem.Tab = .start) {
        self.selectedTab = selectedTab
    }
}

public enum NavigationHub {
    // MARK: - Singleton Flows

    /// Navigation flow for the Summary module.
    public static let summaryFlow = NavigationStackFlow()

    /// Navigation flow for the Report module.
    public static let reportFlow = NavigationStackFlow()

    /// Navigation flow for the Start module.
    public static let startFlow = NavigationStackFlow()

    /// Navigation flow for the Values module.
    public static let valuesFlow = NavigationStackFlow()

    /// Navigation flow for the Export module.
    public static let exportFlow = NavigationStackFlow()

    /// Navigation flow for the Management module.
    public static let managementFlow = NavigationStackFlow()

    /// Navigation flow for the macOS data tools module.
    public static let dataFlow = NavigationStackFlow()

    /// Navigation flow for the macOS pie report sidebar entry.
    public static let reportPieFlow = NavigationStackFlow()

    /// Navigation flow for the macOS line report sidebar entry.
    public static let reportLineFlow = NavigationStackFlow()

    /// Navigation flow for the macOS bar report sidebar entry.
    public static let reportBarFlow = NavigationStackFlow()

    /// Shared tab selection state.
    public static let tabSelection = TabSelection()

    // MARK: - Tab Flow Enum

    /// Represents a tab with its associated navigation flow.
    public enum TabFlow {
        case summary
        case report
        case start
        case values
        case export
        case management

        /// The navigation flow instance for this tab.
        public var navigation: NavigationStackFlow {
            switch self {
            case .summary: NavigationHub.summaryFlow
            case .report: NavigationHub.reportFlow
            case .start: NavigationHub.startFlow
            case .values: NavigationHub.valuesFlow
            case .export: NavigationHub.exportFlow
            case .management: NavigationHub.managementFlow
            }
        }
    }

    // MARK: - Helpers

    /// Returns the flow for the given tab.
    ///
    /// - Parameter tab: The tab whose flow should be used.
    /// - Returns: The matching TabFlow.
    public static func tabFlow(for tab: TabItem.Tab) -> TabFlow {
        switch tab {
        case .summary: .summary
        case .report: .report
        case .start: .start
        case .values: .values
        case .export: .export
        case .bootstrap: .start
        case .management: .management
        }
    }
}
