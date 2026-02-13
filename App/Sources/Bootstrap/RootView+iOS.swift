//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

#if os(iOS) && !targetEnvironment(macCatalyst)
extension RootView {
    /// Creates the iOS tab-based root view.
    var iOSRootView: some View {
        TabView(selection: $selectedTab) {
            TabNavigationContainer(flow: NavigationHub.summaryFlow) {
                OverviewRouteLauncher()
            }
            .tabItem {
                Label(L10n.generalTabOverview, systemImage: TabItem.Tab.summary.icon())
            }
            .tag(TabItem.Tab.summary)

            TabNavigationContainer(flow: NavigationHub.reportFlow) {
                ReportRouteLauncher()
            }
            .tabItem {
                Label(L10n.generalTabOverview, systemImage: TabItem.Tab.report.icon())
            }
            .tag(TabItem.Tab.report)

            TabNavigationContainer(flow: NavigationHub.startFlow) {
                AddTimeRecordView()
            }
            .tabItem {
                Label(L10n.generalTabOverview, systemImage: TabItem.Tab.start.icon())
            }
            .tag(TabItem.Tab.start)

            TabNavigationContainer(flow: NavigationHub.valuesFlow) {
                ManagementView()
            }
            .tabItem {
                Label(valuesTabTitle, systemImage: TabItem.Tab.values.icon())
            }
            .tag(TabItem.Tab.values)

            TabNavigationContainer(flow: NavigationHub.exportFlow) {
                MoreMenuView()
            }
            .tabItem {
                Label(L10n.generalTabExport, systemImage: TabItem.Tab.export.icon())
            }
            .tag(TabItem.Tab.export)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            guard oldValue != newValue else {
                return
            }
            ImpactManager.generateImpactFeedback()
        }
        .task {
            await ensureTrustedPeerHosting()
        }
        .rootPeerSyncApprovalSheet()
    }

    /// Starts local peer hosting in the background when trusted peers already exist.
    private func ensureTrustedPeerHosting() async {
        guard let coordinator = LocalPeerSyncCoordinator.shared else {
            return
        }
        let status = await coordinator.currentStatusSnapshot()
        guard status.hasTrustedPeer else {
            return
        }
        do {
            try coordinator.startHosting()
        } catch {
            localPeerLog(
                "\(LocalPeerSyncCoordinator.logPrefix) Root iOS auto-hosting skipped: \(error.localizedDescription)"
            )
        }
    }
}
#endif
