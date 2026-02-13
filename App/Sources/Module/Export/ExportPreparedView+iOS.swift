//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

#if os(iOS)
extension ExportPreparedView {
    /// Creates the iOS-specific wide layout.
    @ViewBuilder
    var platformWideContent: some View {
        HStack(alignment: .top, spacing: .spacingM) {
            previewContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: .spacingM) {
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text(L10n.exportPreviewSummaryTitle)
                        .textStyle(.title3)
                        .accessibilityAddTraits(.isHeader)

                    Text(item.url.lastPathComponent)
                        .textStyle(.body3)
                        .foregroundStyle(Color.aPrimary.opacity(0.75))
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.spacingM)
                .background(Color.aListBackground)
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius))

                exportActionArea
            }
            .frame(width: 320, alignment: .topLeading)
        }
        .padding(.horizontal, .spacingM)
        .padding(.top, .spacingM)
        .padding(.bottom, .spacingM)
    }

    /// Creates the iOS-specific action area.
    @ViewBuilder
    var exportActionArea: some View {
        exportActionButton
    }

    /// Creates the iOS export/share action button.
    var exportActionButton: some View {
        Button {
            Task { @MainActor in
                guard isPreparingExportShare == false else {
                    return
                }

                isPreparingExportShare = true
                defer { isPreparingExportShare = false }

                let hasPremiumExportEntitlement = await canExportPreparedFile()
                if hasPremiumExportEntitlement {
                    exportActivityItem = ExportActivityItem(url: item.url)
                } else {
                    showsPurchasesSheet = true
                }
            }
        } label: {
            HStack {
                Spacer()
                if isPreparingExportShare {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Text(L10n.exportPreviewExportButton)
                        .textStyle(.button1)
                        .fontWeight(.medium)
                }
                Spacer()
            }
            .frame(minHeight: 48)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isPreparingExportShare)
        .accessibilityLabel(L10n.exportPreviewExportButton)
    }

    /// Validates whether prepared export sharing is available through subscription or lifetime entitlement.
    ///
    /// - Returns: `true` when the current user has subscription or lifetime access.
    private func canExportPreparedFile() async -> Bool {
        await EntitlementStore.shared.refresh(
            context: viewContext,
            includingStoreKitChecks: true
        )

        switch EntitlementStore.shared.accessLevel {
        case .subscription, .lifetime:
            return true
        case .free, .locked:
            return false
        }
    }
}
#endif
