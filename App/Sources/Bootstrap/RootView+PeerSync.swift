//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if os(iOS) && !targetEnvironment(macCatalyst)
import Foundation
import SwiftUI

extension RootView {}

/// Adds incoming peer sync approval handling to root-level iOS views.
extension View {
    /// Attaches the incoming peer sync approval sheet flow.
    ///
    /// - Returns: A view configured with incoming sync approval presentation.
    func rootPeerSyncApprovalSheet() -> some View {
        modifier(RootPeerSyncApprovalModifier())
    }
}

/// Displays a confirmation sheet for incoming peer sync requests.
private struct RootPeerSyncApprovalModifier: ViewModifier {
    /// Stores one pending incoming sync approval request.
    @State private var pendingIncomingSyncApproval: IncomingSyncApprovalRequest?

    /// Builds the modified view hierarchy.
    ///
    /// - Parameter content: The wrapped root content.
    /// - Returns: The content with incoming approval handling attached.
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: LocalPeerSyncNotifications.incomingSyncApprovalRequested)) { notification in
                handleIncomingSyncApproval(notification: notification)
            }
            .sheet(item: $pendingIncomingSyncApproval) { request in
                incomingSyncApprovalSheet(for: request)
            }
    }

    /// Handles one incoming sync approval request notification.
    ///
    /// - Parameter notification: The posted incoming approval notification.
    private func handleIncomingSyncApproval(notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let peerId = userInfo[LocalPeerSyncNotifications.peerIdKey] as? String
        else {
            return
        }
        let deviceName = (userInfo[LocalPeerSyncNotifications.deviceNameKey] as? String) ?? "Device"
        pendingIncomingSyncApproval = IncomingSyncApprovalRequest(peerId: peerId, deviceName: deviceName)
    }

    /// Builds the approval sheet for one incoming sync request.
    ///
    /// - Parameter request: The pending incoming sync request.
    /// - Returns: A sheet prompting the user to allow or deny sync.
    @ViewBuilder
    private func incomingSyncApprovalSheet(for request: IncomingSyncApprovalRequest) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: .spacingM) {
                Text(L10n.settingsPeerSyncIncomingSyncTitle)
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)

                Text(L10n.settingsPeerSyncIncomingSyncMessage(request.deviceName))
                    .textStyle(.body2)
                    .foregroundStyle(Color.aPrimary.opacity(0.7))

                HStack(spacing: .spacingS) {
                    Button(L10n.measurementInputCancel) {
                        pendingIncomingSyncApproval = nil
                    }
                    .buttonStyle(SecondaryButtonStyle(size: .small))

                    Button(L10n.settingsPeerSyncIncomingSyncAllow) {
                        let approvedPeerId = request.peerId
                        pendingIncomingSyncApproval = nil
                        Task { @MainActor in
                            guard let coordinator = LocalPeerSyncCoordinator.shared else {
                                return
                            }
                            coordinator.approveIncomingSync(for: approvedPeerId)
                            do {
                                try await coordinator.syncNow(with: approvedPeerId)
                            } catch {
                                localPeerLog(
                                    "\(LocalPeerSyncCoordinator.logPrefix) Incoming sync approval syncNow failed: \(error.localizedDescription)"
                                )
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(size: .small))
                }
            }
            .padding(.spacingM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.aBackground)
            .foregroundStyle(Color.aPrimary)
            .navigationTitle(L10n.settingsPeerSyncIncomingSyncTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

/// Represents one incoming sync approval request shown in the root sheet.
private struct IncomingSyncApprovalRequest: Identifiable {
    /// The stable request identifier used by SwiftUI sheets.
    let id: String

    /// The trusted peer identifier requesting sync.
    let peerId: String

    /// The trusted peer device name requesting sync.
    let deviceName: String

    /// Creates one incoming sync approval request model.
    ///
    /// - Parameters:
    ///   - peerId: The trusted peer identifier.
    ///   - deviceName: The trusted peer display name.
    init(peerId: String, deviceName: String) {
        id = peerId
        self.peerId = peerId
        self.deviceName = deviceName
    }
}
#endif
