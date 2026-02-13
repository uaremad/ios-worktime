//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if os(macOS)
import AppKit
import CoreImage.CIFilterBuiltins
import Foundation
import SwiftUI

/// Presents the macOS onboarding flow for local peer pairing with iOS.
@MainActor
struct LocalPeerSyncHostIntroView: View {
    /// Opens external URLs such as the iOS App Store page.
    @Environment(\.openURL) private var openURL

    /// Defines how the host intro view is presented.
    enum PresentationStyle: Sendable {
        /// Renders the view as a full screen page with scroll and navigation title.
        case fullScreen
        /// Renders the view as embedded content without scroll or navigation title.
        case embedded
    }

    /// The selected presentation style for the view.
    private let presentationStyle: PresentationStyle

    /// Stores the latest generated QR code image.
    @State private var qrCodeImage: NSImage?

    /// Tracks whether host setup is currently in progress.
    @State private var isPreparingPairing: Bool = false

    /// Controls presentation of a generic error alert.
    @State private var showsErrorAlert: Bool = false

    /// Stores the latest error message shown in the alert.
    @State private var errorMessage: String = ""

    /// Stores the latest persisted synchronization status.
    @State private var statusSnapshot: LocalPeerSyncStatusSnapshot = .empty

    /// Stores the currently connected peer identifier if available.
    @State private var connectedPeerId: String?

    /// Stores the currently connected peer display name if available.
    @State private var connectedPeerName: String?

    /// Controls presentation of the sync confirmation sheet.
    @State private var showsSyncConfirmationSheet: Bool = false

    /// Tracks whether a manual sync request is currently running.
    @State private var isSyncingNow: Bool = false

    /// Controls presentation of the QR code sheet for embedded mode.
    @State private var showsPairingQRCodeSheet: Bool = false

    /// Holds the reconnect timeout task for missing expected iOS peer alerts.
    @State private var reconnectTimeoutAlertTask: Task<Void, Never>?

    /// Indicates whether reconnect is waiting for the expected iOS peer.
    @State private var isWaitingForReconnectPeer: Bool = false

    /// Shared Core Image context for QR rendering.
    private let qrContext: CIContext = .init()

    /// Creates a macOS host intro view.
    ///
    /// - Parameter presentationStyle: The style used to render the view layout.
    init(presentationStyle: PresentationStyle = .fullScreen) {
        self.presentationStyle = presentationStyle
    }

    /// The body of the macOS introduction view.
    var body: some View {
        contentContainer
            .frame(
                maxWidth: .infinity,
                maxHeight: presentationStyle == .fullScreen ? .infinity : nil,
                alignment: .topLeading
            )
            .background(presentationStyle == .fullScreen ? Color.aBackground : Color.clear)
            .foregroundStyle(Color.aPrimary)
            .modifier(NavigationTitleModifier(
                isActive: presentationStyle == .fullScreen,
                title: L10n.generalMoreTransferToIos
            ))
            .task {
                await loadStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: LocalPeerSyncNotifications.peerConnected)) { notification in
                handlePeerConnected(notification: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: LocalPeerSyncNotifications.syncActivityChanged)) { notification in
                handleSyncActivity(notification: notification)
            }
            .sheet(isPresented: $showsSyncConfirmationSheet) {
                syncConfirmationSheet
            }
            .sheet(isPresented: $showsPairingQRCodeSheet) {
                pairingQRCodeSheet
            }
            .alert(L10n.errorBackupExportTitle, isPresented: $showsErrorAlert) {
                Button(L10n.generalOk, role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
    }

    /// Creates the content container based on the selected presentation style.
    @ViewBuilder
    private var contentContainer: some View {
        if presentationStyle == .fullScreen {
            ScrollView {
                content
                    .padding(.horizontal)
                    .padding(.top, .spacingM)
            }
        } else {
            content
        }
    }

    /// Renders the shared content for both presentation styles.
    @ViewBuilder
    private var content: some View {
        if presentationStyle == .embedded {
            VStack(alignment: .leading, spacing: .spacingM) {
                HStack(alignment: .top, spacing: .spacingM) {
                    introCard
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    statusCard
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }

                syncActionButton
            }
            .padding(.spacingS)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadius)
                    .fill(Color.aListBackground)
            )
        } else {
            VStack(alignment: .leading, spacing: .spacingM) {
                introCard
                statusCard
            }
        }
    }

    /// Renders the intro card with explanation, action button, and QR code.
    private var introCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack(spacing: .spacingXS) {
                Image(systemName: "qrcode")
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                Text(L10n.generalMoreTransferToIos)
                    .textStyle(.title3)
                    .foregroundStyle(Color.aPrimary)
                    .accessibilityAddTraits(.isHeader)
            }

            Text(introHintText)
                .textStyle(.body1)
                .foregroundStyle(Color.aPrimary.opacity(0.7))

            if presentationStyle == .fullScreen {
                syncActionButton
            }

            if presentationStyle == .fullScreen, connectedPeerId == nil, let qrCodeImage {
                VStack(alignment: .center, spacing: .spacingS) {
                    Image(nsImage: qrCodeImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 280, maxHeight: 280)
                        .accessibilityLabel(L10n.generalMoreTransferToIos)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(presentationStyle == .embedded ? 0 : .spacingS)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadius)
                .fill(presentationStyle == .embedded ? Color.clear : Color.aListBackground)
        )
    }

    /// Renders the primary peer sync action button based on connection state.
    @ViewBuilder
    private var syncActionButton: some View {
        if connectedPeerId == nil {
            Button {
                Task {
                    if statusSnapshot.hasTrustedPeer {
                        if await reconnectToTrustedPeer() {
                            isWaitingForReconnectPeer = true
                            scheduleReconnectNotFoundAlert()
                        }
                    } else {
                        await startPairingFlow()
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    if isPreparingPairing || isWaitingForReconnectPeer {
                        ProgressView()
                            .accessibilityLabel(L10n.generalOk)
                    } else {
                        Text(statusSnapshot.hasTrustedPeer ? L10n.settingsPeerSyncReconnectNow : L10n.settingsPeerSyncConnectNow)
                            .textStyle(.body1)
                    }
                    Spacer()
                }
            }
            .buttonStyle(TertiaryButtonStyle())
            .disabled(isPreparingPairing || isWaitingForReconnectPeer)
            .accessibilityLabel(statusSnapshot.hasTrustedPeer ? L10n.settingsPeerSyncReconnectNow : L10n.settingsPeerSyncConnectNow)
            .accessibilityHint(L10n.generalMoreTransferToIos)
        } else {
            Button {
                showsSyncConfirmationSheet = true
            } label: {
                HStack {
                    Spacer()
                    if isSyncingNow {
                        ProgressView()
                            .accessibilityLabel(L10n.generalOk)
                    } else {
                        Text(L10n.settingsPeerSyncSyncNow)
                            .textStyle(.body1)
                    }
                    Spacer()
                }
            }
            .buttonStyle(TertiaryButtonStyle())
            .disabled(isSyncingNow)
            .accessibilityLabel(L10n.settingsPeerSyncSyncNow)
            .accessibilityHint(L10n.settingsPeerSyncStatusPeerAvailable)
        }
    }

    /// Renders the persisted local peer sync status card.
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack(spacing: .spacingXS) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                Text(L10n.settingsPeerSyncStatusTitle)
                    .textStyle(.title3)
                    .foregroundStyle(Color.aPrimary)
                    .accessibilityAddTraits(.isHeader)
            }

            if statusSnapshot.hasTrustedPeer {
                statusRow(
                    title: L10n.settingsPeerSyncStatusPeerAvailable,
                    value: "\(statusSnapshot.peerCount)"
                )
                statusRow(
                    title: L10n.settingsPeerSyncStatusLastTransfer,
                    value: lastTransferText
                )
                statusRow(
                    title: L10n.settingsPeerSyncStatusSyncedData,
                    value: ByteCountFormatter.string(
                        fromByteCount: statusSnapshot.totalSyncedBytes,
                        countStyle: .file
                    )
                )
            } else {
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text(L10n.settingsPeerSyncStatusNoPeer)
                        .textStyle(.body1)
                        .foregroundStyle(Color.aPrimary.opacity(0.7))

                    if AppInfo().iosAppStoreURL != nil {
                        Button {
                            openiOSAppStore()
                        } label: {
                            Label(L10n.settingsPeerSyncShowIosApp, systemImage: "iphone")
                        }
                        .buttonStyle(TextButtonStyle(foregroundColor: Color.accentColor))
                        .accessibilityLabel(L10n.settingsPeerSyncShowIosApp)
                        .accessibilityHint(L10n.accessibilityPeerSyncShowIosAppHint)
                        .accessibilityAddTraits(.isLink)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(presentationStyle == .embedded ? 0 : .spacingS)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadius)
                .fill(presentationStyle == .embedded ? Color.clear : Color.aListBackground)
        )
    }

    /// Returns the formatted last transfer value for status rendering.
    private var lastTransferText: String {
        guard let lastTransferAt = statusSnapshot.lastTransferAt else {
            return L10n.settingsPeerSyncStatusNever
        }
        return lastTransferAt.formatted(date: .abbreviated, time: .shortened)
    }

    /// Returns the introduction hint depending on current connection state.
    private var introHintText: String {
        guard let connectedPeerName else {
            if statusSnapshot.hasTrustedPeer {
                return L10n.settingsPeerSyncReconnectHint
            }
            return L10n.settingsPeerSyncIntroHint
        }
        if isSyncingNow {
            return L10n.settingsPeerSyncSyncingHint(connectedPeerName)
        }
        return L10n.settingsPeerSyncConnectedHint(connectedPeerName)
    }

    /// Opens the App Store product page for the iOS/iPadOS app.
    private func openiOSAppStore() {
        guard let url = AppInfo().iosAppStoreURL else {
            return
        }
        openURL(url) { accepted in
            if accepted == false {
                errorMessage = L10n.errorBackupExportMessage
                showsErrorAlert = true
            }
        }
    }
}

private extension LocalPeerSyncHostIntroView {
    /// Starts local hosting and generates a fresh QR payload for iOS scanning.
    func startPairingFlow() async {
        guard isPreparingPairing == false else {
            localPeerLog("[LOCAL SYNC][macOS][HostIntro] Ignored startPairingFlow because it is already running")
            return
        }

        localPeerLog("[LOCAL SYNC][macOS][HostIntro] Starting pairing flow from UI action")
        isPreparingPairing = true
        defer {
            isPreparingPairing = false
            localPeerLog("[LOCAL SYNC][macOS][HostIntro] Pairing flow finished")
        }

        guard let coordinator = LocalPeerSyncCoordinator.shared else {
            localPeerLog("[LOCAL SYNC][macOS][HostIntro] Missing coordinator while starting pairing flow")
            errorMessage = L10n.errorBackupExportMessage
            showsErrorAlert = true
            return
        }

        do {
            try coordinator.startHosting()
            localPeerLog("[LOCAL SYNC][macOS][HostIntro] Hosting started")
            isWaitingForReconnectPeer = false
            connectedPeerId = nil
            connectedPeerName = nil
            let payload = coordinator.createPairingPayload()
            let qrPayload = try coordinator.makeQRCodeString(from: payload)
            localPeerLog(
                "[LOCAL SYNC][macOS][HostIntro] Generated QR payload session id=\(payload.pairingSessionId.uuidString) characters=\(qrPayload.count)"
            )
            guard let image = makeQRCodeImage(from: qrPayload) else {
                localPeerLog("[LOCAL SYNC][macOS][HostIntro] QR image rendering failed")
                throw LocalPeerSyncCoordinatorError.invalidPairingSession
            }
            qrCodeImage = image
            if presentationStyle == .embedded {
                showsPairingQRCodeSheet = true
            }
            localPeerLog("[LOCAL SYNC][macOS][HostIntro] QR image rendered and displayed")
            await loadStatus()
        } catch {
            localPeerLog("[LOCAL SYNC][macOS][HostIntro] Pairing flow failed: \(error.localizedDescription)")
            showsPairingQRCodeSheet = false
            errorMessage = L10n.errorBackupExportMessage
            showsErrorAlert = true
        }
    }

    /// Reconnects to an already trusted peer without creating a fresh QR code.
    ///
    /// - Returns: `true` when reconnect browsing started successfully.
    func reconnectToTrustedPeer() async -> Bool {
        guard let coordinator = LocalPeerSyncCoordinator.shared else {
            errorMessage = L10n.errorBackupExportMessage
            showsErrorAlert = true
            return false
        }
        guard isPreparingPairing == false else {
            return false
        }

        isPreparingPairing = true
        defer {
            isPreparingPairing = false
        }

        do {
            qrCodeImage = nil
            showsPairingQRCodeSheet = false
            try await coordinator.reconnectToTrustedPeer()
            return true
        } catch {
            isWaitingForReconnectPeer = false
            localPeerLog("\(LocalPeerSyncCoordinator.logPrefix) HostIntro reconnect failed: \(error.localizedDescription)")
            errorMessage = L10n.errorBackupExportMessage
            showsErrorAlert = true
            return false
        }
    }

    /// Handles a peer-connected event and prepares sync confirmation UI.
    ///
    /// - Parameter notification: The delivered peer connection notification.
    func handlePeerConnected(notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let peerId = userInfo[LocalPeerSyncNotifications.peerIdKey] as? String
        else {
            return
        }
        let deviceName = userInfo[LocalPeerSyncNotifications.deviceNameKey] as? String
        connectedPeerId = peerId
        connectedPeerName = deviceName
        qrCodeImage = nil
        showsPairingQRCodeSheet = false
        isPreparingPairing = false
        isWaitingForReconnectPeer = false
        reconnectTimeoutAlertTask?.cancel()
        reconnectTimeoutAlertTask = nil
        showsSyncConfirmationSheet = true
        localPeerLog("\(LocalPeerSyncCoordinator.logPrefix) HostIntro received peerConnected for peer=\(peerId)")
    }

    /// Handles a sync activity event and updates progress UI for this peer.
    ///
    /// - Parameter notification: The delivered sync activity notification.
    func handleSyncActivity(notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let peerId = userInfo[LocalPeerSyncNotifications.peerIdKey] as? String,
              let isSyncing = userInfo[LocalPeerSyncNotifications.isSyncingKey] as? Bool
        else {
            return
        }
        let deviceName = userInfo[LocalPeerSyncNotifications.deviceNameKey] as? String
        if connectedPeerId == nil {
            connectedPeerId = peerId
        }
        if connectedPeerId != peerId {
            if let deviceName, deviceName == connectedPeerName {
                connectedPeerId = peerId
            } else {
                return
            }
        }
        if let deviceName {
            connectedPeerName = deviceName
        }
        if connectedPeerId != nil {
            isWaitingForReconnectPeer = false
            reconnectTimeoutAlertTask?.cancel()
            reconnectTimeoutAlertTask = nil
        }
        isSyncingNow = isSyncing
        if isSyncing {
            showsSyncConfirmationSheet = false
        }
        localPeerLog(
            "\(LocalPeerSyncCoordinator.logPrefix) HostIntro received syncActivityChanged " +
                "peer=\(peerId) isSyncing=\(isSyncing)"
        )
    }

    /// Performs a manual sync for the currently connected peer.
    func syncNow() async {
        guard let peerId = connectedPeerId else {
            return
        }
        guard let coordinator = LocalPeerSyncCoordinator.shared else {
            errorMessage = L10n.errorBackupExportMessage
            showsErrorAlert = true
            return
        }

        isSyncingNow = true
        defer {
            isSyncingNow = false
        }

        do {
            try await coordinator.syncNow(with: peerId)
            await loadStatus()
            localPeerLog("\(LocalPeerSyncCoordinator.logPrefix) HostIntro manual sync started for peer=\(peerId)")
        } catch {
            localPeerLog("\(LocalPeerSyncCoordinator.logPrefix) HostIntro manual sync failed: \(error.localizedDescription)")
            errorMessage = L10n.errorBackupExportMessage
            showsErrorAlert = true
        }
    }

    /// Loads persisted synchronization status from the coordinator.
    func loadStatus() async {
        guard let coordinator = LocalPeerSyncCoordinator.shared else {
            localPeerLog("[LOCAL SYNC][macOS][HostIntro] loadStatus fallback: coordinator is unavailable")
            statusSnapshot = .empty
            return
        }
        statusSnapshot = await coordinator.currentStatusSnapshot()
        if statusSnapshot.hasTrustedPeer {
            do {
                try coordinator.startHosting()
            } catch {
                localPeerLog(
                    "[LOCAL SYNC][macOS][HostIntro] startHosting skipped during status load: \(error.localizedDescription)"
                )
            }
        }
        let hasTrustedPeer = statusSnapshot.hasTrustedPeer
        let peerCount = statusSnapshot.peerCount
        let totalSyncedBytes = statusSnapshot.totalSyncedBytes
        localPeerLog(
            "[LOCAL SYNC][macOS][HostIntro] Loaded status " +
                "hasTrustedPeer=\(hasTrustedPeer) peers=\(peerCount) totalBytes=\(totalSyncedBytes)"
        )
    }

    /// Creates a rendered QR image from a payload string.
    ///
    /// - Parameter payload: The encoded payload for scanner transfer.
    /// - Returns: A platform image that can be displayed in SwiftUI.
    func makeQRCodeImage(from payload: String) -> NSImage? {
        guard let payloadData = payload.data(using: .utf8) else {
            localPeerLog("[LOCAL SYNC][macOS][HostIntro] Failed to convert QR payload string to UTF-8 data")
            return nil
        }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = payloadData
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else {
            localPeerLog("[LOCAL SYNC][macOS][HostIntro] QR filter produced no output image")
            return nil
        }
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = qrContext.createCGImage(scaledImage, from: scaledImage.extent) else {
            localPeerLog("[LOCAL SYNC][macOS][HostIntro] Failed to create CGImage from QR output")
            return nil
        }

        return NSImage(
            cgImage: cgImage,
            size: NSSize(width: scaledImage.extent.width, height: scaledImage.extent.height)
        )
    }

    /// Builds one key-value row for status information.
    ///
    /// - Parameters:
    ///   - title: The localized row title.
    ///   - value: The formatted row value.
    /// - Returns: The status row view.
    @ViewBuilder
    func statusRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .textStyle(.body1)
            Spacer()
            Text(value)
                .textStyle(.body1)
                .foregroundStyle(Color.aPrimary.opacity(0.7))
        }
        .accessibilityElement(children: .combine)
    }

    /// Schedules a reconnect timeout alert when no expected iOS peer is found.
    func scheduleReconnectNotFoundAlert() {
        reconnectTimeoutAlertTask?.cancel()
        reconnectTimeoutAlertTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(8))
            guard connectedPeerId == nil else {
                return
            }
            isWaitingForReconnectPeer = false
            showsPairingQRCodeSheet = false
            errorMessage = L10n.settingsPeerSyncReconnectPeerNotFoundMessage
            showsErrorAlert = true
        }
    }
}

/// Applies a navigation title only when enabled.
private struct NavigationTitleModifier: ViewModifier {
    /// Whether the navigation title should be applied.
    let isActive: Bool

    /// The localized navigation title.
    let title: String

    /// Applies the modifier to the content view.
    ///
    /// - Parameter content: The base content view.
    /// - Returns: The content with or without a navigation title.
    func body(content: Content) -> some View {
        if isActive {
            content.navigationTitle(title)
        } else {
            content
        }
    }
}

private extension LocalPeerSyncHostIntroView {
    /// Renders the sheet that displays the generated pairing QR code in embedded mode.
    var pairingQRCodeSheet: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            Text(L10n.generalMoreTransferToIos)
                .textStyle(.title3)
                .accessibilityAddTraits(.isHeader)

            Text(L10n.settingsPeerSyncIntroHint)
                .textStyle(.body2)
                .foregroundStyle(Color.aPrimary.opacity(0.7))

            if let qrCodeImage {
                Image(nsImage: qrCodeImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 240, maxHeight: 240)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityLabel(L10n.generalMoreTransferToIos)
            }

            HStack {
                Spacer()
                Button(L10n.generalOk) {
                    showsPairingQRCodeSheet = false
                }
                .buttonStyle(PrimaryButtonStyle(size: .small))
                .focusable(false)
            }
        }
        .padding(.spacingM)
        .frame(minWidth: 360, maxWidth: 420)
        .background(Color.aBackground)
        .foregroundStyle(Color.aPrimary)
    }

    /// Renders the sheet asking whether synchronization should start now.
    var syncConfirmationSheet: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            Text(L10n.settingsPeerSyncStatusTitle)
                .textStyle(.title3)
                .accessibilityAddTraits(.isHeader)

            Text(L10n.settingsPeerSyncStatusPeerAvailable)
                .textStyle(.body2)
                .foregroundStyle(Color.aPrimary.opacity(0.7))

            HStack(spacing: .spacingS) {
                Button(L10n.measurementInputCancel) {
                    showsSyncConfirmationSheet = false
                }
                .buttonStyle(SecondaryButtonStyle(size: .small))

                Button {
                    showsSyncConfirmationSheet = false
                    Task {
                        await syncNow()
                    }
                } label: {
                    if isSyncingNow {
                        ProgressView()
                            .accessibilityLabel(L10n.generalOk)
                    } else {
                        Text(L10n.settingsPeerSyncSyncNow)
                    }
                }
                .buttonStyle(PrimaryButtonStyle(size: .small))
                .disabled(isSyncingNow)
            }
        }
        .padding(.spacingM)
        .frame(minWidth: 420)
        .background(Color.aBackground)
        .foregroundStyle(Color.aPrimary)
    }
}
#endif
