//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Resolves navigation routes to destination views.
struct NavigationDestinations: View {
    /// The route to resolve into a destination view.
    let route: NavigationStackRoute

    /// The managed object context used for fetching entities.
    @Environment(\.managedObjectContext) private var viewContext

    /// The resolved destination view for the current route.
    var body: some View {
        destinationView
            .appThemeColors()
    }

    /// Maps a navigation route to its destination view.
    @ViewBuilder
    private var destinationView: some View {
        switch route {
        case let .module(destination):
            switch destination {
            case .overview:
                OverviewView()
            case .reporting:
                ReportingView()
            case .imprint:
                ImprintView()
            case .privacyPolicy:
                PrivacyPolicyView()
            case .export:
                ExportDateRangeView(context: viewContext)
            case .importData:
                ImportCSVView(context: viewContext)
            case .reminder:
                EmptyView()
            case .icloud:
                ICloudSyncView()
            case .peerSyncIntro:
                #if os(iOS) && !targetEnvironment(macCatalyst)
                LocalPeerSyncIntroView()
                #elseif os(macOS)
                LocalPeerSyncHostIntroView()
                #else
                EmptyView()
                #endif
            case .purchases:
                MoreMenuPurchasesView()
            case let .timeRecordsList(filter):
                TimeRecordsListView(initialFilter: filter)
            case .billingSettings:
                BillingSettingsView()
            case .invoicingSettings:
                InvoicingSettingsView()
            case .activitySettings:
                ActivitySettingsListView()
            case .terminologySettings:
                TerminologySettingsView()
            case .costCentreSettings:
                CostCentreListView()
            }
        }
    }
}
