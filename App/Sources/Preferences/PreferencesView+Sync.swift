//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if os(macOS)
import SwiftUI

extension PreferencesView {
    /// The sync and export settings view.
    ///
    /// transferring data between devices, and exporting/importing data.
    var syncSettings: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacingM) {
                sectionHeader(L10n.generalMoreSectionExport)

                VStack(spacing: .spacingS) {
                    // Transfer/Peer Sync
                    NavigationLink(value: NavigationStackRoute.module(.peerSyncIntro)) {
                        settingsRow(
                            title: L10n.generalMoreTransferToIos,
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: Color.accentColor
                        )
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.leading, 44)

                    // Export
                    NavigationLink(value: NavigationStackRoute.module(.export)) {
                        settingsRow(
                            title: L10n.generalMoreExportTitle,
                            icon: "square.and.arrow.up",
                            iconColor: Color.accentColor
                        )
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.leading, 44)

                    // Import
                    NavigationLink(value: NavigationStackRoute.module(.importData)) {
                        settingsRow(
                            title: L10n.generalMoreImportTitle,
                            icon: "square.and.arrow.down",
                            iconColor: Color.accentColor
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: .cornerRadius)
                        .fill(Color.aListBackground)
                )
            }
            .padding()
        }
    }
}

#endif
