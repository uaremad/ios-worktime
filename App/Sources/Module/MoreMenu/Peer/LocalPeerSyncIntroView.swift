//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if os(iOS) && !targetEnvironment(macCatalyst)
import AVFoundation
import SwiftUI
import UIKit

/// Presents the iOS onboarding and scanner flow for local peer pairing.
@MainActor
struct LocalPeerSyncIntroView: View {
    /// Controls whether the scanner is currently visible.
    @State private var showsScanner: Bool = false

    /// Tracks whether a QR payload is currently being processed.
    @State private var isProcessing: Bool = false

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

    /// Controls presentation of the sync confirmation prompt.
    @State private var showsSyncConfirmation: Bool = false

    /// Tracks whether a manual sync request is currently running.
    @State private var isSyncingNow: Bool = false

    /// The body of the introduction view.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingM) {
                VStack(alignment: .leading, spacing: .spacingM) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.largeTitle)
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)

                    Text(L10n.generalMoreTransferToMac)
                        .textStyle(.title2)
                        .accessibilityAddTraits(.isHeader)

                    Text(introHintText)
                        .textStyle(.body2)
                        .foregroundStyle(Color.aPrimary.opacity(0.7))

                    if connectedPeerId == nil {
                        Button {
                            if statusSnapshot.hasTrustedPeer {
                                Task {
                                    await reconnectToTrustedPeer()
                                }
                            } else {
                                showsScanner = true
                            }
                        } label: {
                            HStack {
                                Spacer()
                                if isProcessing {
                                    ProgressView()
                                        .accessibilityLabel(L10n.generalOk)
                                } else {
                                    Text(statusSnapshot.hasTrustedPeer ? L10n.settingsPeerSyncReconnectNow : L10n.settingsPeerSyncConnectNow)
                                        .textStyle(.body1)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isProcessing)
                        .accessibilityLabel(statusSnapshot.hasTrustedPeer ? L10n.settingsPeerSyncReconnectNow : L10n.settingsPeerSyncConnectNow)
                        .accessibilityHint(L10n.generalMoreTransferToMac)
                    } else {
                        Button {
                            showsSyncConfirmation = true
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
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isSyncingNow)
                        .accessibilityLabel(L10n.settingsPeerSyncSyncNow)
                        .accessibilityHint(L10n.settingsPeerSyncStatusPeerAvailable)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.spacingS)
                .background(
                    RoundedRectangle(cornerRadius: .cornerRadius)
                        .fill(Color.aListBackground)
                )

                VStack(alignment: .leading, spacing: .spacingS) {
                    Text(L10n.settingsPeerSyncStatusTitle)
                        .textStyle(.title3)
                        .accessibilityAddTraits(.isHeader)

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
                        Text(L10n.settingsPeerSyncStatusNoPeer)
                            .textStyle(.body2)
                            .foregroundStyle(Color.aPrimary.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.spacingS)
                .background(
                    RoundedRectangle(cornerRadius: .cornerRadius)
                        .fill(Color.aListBackground)
                )
            }
            .padding(.horizontal)
            .padding(.top, .spacingM)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.aBackground)
        .foregroundStyle(Color.aPrimary)
        .navigationTitle(L10n.generalMoreTransferToMac)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: LocalPeerSyncNotifications.peerConnected)) { notification in
            handlePeerConnected(notification: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: LocalPeerSyncNotifications.syncActivityChanged)) { notification in
            handleSyncActivity(notification: notification)
        }
        .fullScreenCover(isPresented: $showsScanner) {
            LocalPeerSyncScannerContainer(
                onCodeScanned: { scannedValue in
                    process(scannedValue: scannedValue)
                },
                onDismiss: {
                    showsScanner = false
                }
            )
        }
        .alert(L10n.errorBackupExportTitle, isPresented: $showsErrorAlert) {
            Button(L10n.generalOk, role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert(L10n.settingsPeerSyncStatusTitle, isPresented: $showsSyncConfirmation) {
            Button(L10n.measurementInputCancel, role: .cancel) {}
            Button(L10n.settingsPeerSyncSyncNow) {
                Task {
                    await syncNow()
                }
            }
        } message: {
            Text(L10n.settingsPeerSyncStatusPeerAvailable)
        }
    }
}

private extension LocalPeerSyncIntroView {
    /// Returns the formatted last transfer value for status rendering.
    var lastTransferText: String {
        guard let lastTransferAt = statusSnapshot.lastTransferAt else {
            return L10n.settingsPeerSyncStatusNever
        }
        return lastTransferAt.formatted(date: .abbreviated, time: .shortened)
    }

    /// Returns the introduction hint depending on current connection state.
    var introHintText: String {
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
}

private extension LocalPeerSyncIntroView {
    /// Handles scanned QR values and starts pairing handshake.
    ///
    /// - Parameter scannedValue: The scanned Base64 QR payload.
    func process(scannedValue: String) {
        guard isProcessing == false else {
            localPeerLog("[LOCAL SYNC][iOS][Intro] Ignored scan because processing is already active")
            return
        }

        localPeerLog("[LOCAL SYNC][iOS][Intro] Received scanned QR payload characters=\(scannedValue.count)")
        isProcessing = true
        showsScanner = false

        Task {
            do {
                guard let coordinator = LocalPeerSyncCoordinator.shared else {
                    localPeerLog("[LOCAL SYNC][iOS][Intro] Missing coordinator while processing QR payload")
                    throw LocalPeerSyncCoordinatorError.invalidPairingSession
                }
                let payload = try coordinator.parseQRCodePayload(scannedValue)
                let sessionId = payload.pairingSessionId.uuidString
                let expiresAt = payload.expiresAt.ISO8601Format()
                localPeerLog(
                    "[LOCAL SYNC][iOS][Intro] Parsed QR payload " +
                        "session id=\(sessionId) expiresAt=\(expiresAt)"
                )
                try await coordinator.pairWithPeer(using: payload)
                localPeerLog("[LOCAL SYNC][iOS][Intro] Pairing flow started successfully")
                await loadStatus()
            } catch {
                localPeerLog("[LOCAL SYNC][iOS][Intro] Pairing flow failed: \(error.localizedDescription)")
                errorMessage = L10n.errorBackupExportMessage
                showsErrorAlert = true
            }
            isProcessing = false
            localPeerLog("[LOCAL SYNC][iOS][Intro] Processing finished")
        }
    }

    /// Loads persisted synchronization status from the coordinator.
    func loadStatus() async {
        guard let coordinator = LocalPeerSyncCoordinator.shared else {
            localPeerLog("[LOCAL SYNC][iOS][Intro] loadStatus fallback: coordinator is unavailable")
            statusSnapshot = .empty
            return
        }
        statusSnapshot = await coordinator.currentStatusSnapshot()
        if statusSnapshot.hasTrustedPeer {
            do {
                try coordinator.startHosting()
            } catch {
                localPeerLog(
                    "[LOCAL SYNC][iOS][Intro] startHosting skipped during status load: \(error.localizedDescription)"
                )
            }
        }
        let hasTrustedPeer = statusSnapshot.hasTrustedPeer
        let peerCount = statusSnapshot.peerCount
        let totalSyncedBytes = statusSnapshot.totalSyncedBytes
        localPeerLog(
            "[LOCAL SYNC][iOS][Intro] Loaded status " +
                "hasTrustedPeer=\(hasTrustedPeer) peers=\(peerCount) totalBytes=\(totalSyncedBytes)"
        )
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
        showsScanner = false
        isProcessing = false
        showsSyncConfirmation = true
        localPeerLog("\(LocalPeerSyncCoordinator.logPrefix) Intro received peerConnected for peer=\(peerId)")
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
        isSyncingNow = isSyncing
        if isSyncing {
            showsSyncConfirmation = false
        }
        localPeerLog(
            "\(LocalPeerSyncCoordinator.logPrefix) Intro received syncActivityChanged " +
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
            localPeerLog("\(LocalPeerSyncCoordinator.logPrefix) Intro manual sync started for peer=\(peerId)")
        } catch {
            localPeerLog("\(LocalPeerSyncCoordinator.logPrefix) Intro manual sync failed: \(error.localizedDescription)")
            errorMessage = L10n.errorBackupExportMessage
            showsErrorAlert = true
        }
    }

    /// Reconnects to an already trusted peer without opening the QR scanner.
    func reconnectToTrustedPeer() async {
        guard let coordinator = LocalPeerSyncCoordinator.shared else {
            errorMessage = L10n.errorBackupExportMessage
            showsErrorAlert = true
            return
        }
        guard isProcessing == false else {
            return
        }

        isProcessing = true
        defer {
            isProcessing = false
        }

        do {
            try await coordinator.reconnectToTrustedPeer()
        } catch {
            localPeerLog("\(LocalPeerSyncCoordinator.logPrefix) Intro reconnect failed: \(error.localizedDescription)")
            errorMessage = L10n.errorBackupExportMessage
            showsErrorAlert = true
        }
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
                .textStyle(.body2)
            Spacer()
            Text(value)
                .textStyle(.body2)
                .foregroundStyle(Color.aPrimary.opacity(0.7))
        }
        .accessibilityElement(children: .combine)
    }
}

/// Wraps the camera scanner and provides a navigation container with dismiss action.
@MainActor
private struct LocalPeerSyncScannerContainer: View {
    /// Callback invoked with the first detected QR code value.
    let onCodeScanned: (String) -> Void

    /// Callback invoked when user closes the scanner.
    let onDismiss: () -> Void

    /// The body of the scanner container.
    var body: some View {
        ZStack(alignment: .topLeading) {
            LocalPeerSyncScannerView(onCodeScanned: onCodeScanned)
                .ignoresSafeArea()

            Button(L10n.measurementInputCancel) {
                onDismiss()
            }
            .padding(.spacingM)
            .buttonStyle(SecondaryButtonStyle(size: .small))
            .accessibilityLabel(L10n.measurementInputCancel)
        }
    }
}

/// Renders a camera preview and emits detected QR payloads.
private struct LocalPeerSyncScannerView: UIViewControllerRepresentable {
    /// Callback invoked with the first detected QR payload.
    let onCodeScanned: (String) -> Void

    /// Creates the scanner view controller.
    ///
    /// - Parameter context: The representable context.
    /// - Returns: A configured scanner view controller.
    func makeUIViewController(context _: Context) -> LocalPeerSyncScannerViewController {
        let controller = LocalPeerSyncScannerViewController()
        controller.onCodeScanned = onCodeScanned
        return controller
    }

    /// Updates the scanner view controller.
    ///
    /// - Parameters:
    ///   - uiViewController: The scanner controller.
    ///   - context: The representable context.
    func updateUIViewController(_: LocalPeerSyncScannerViewController, context _: Context) {}
}

/// Hosts AVCapture session and QR metadata callbacks.
private final class LocalPeerSyncScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    /// Callback invoked when a QR code is detected.
    var onCodeScanned: ((String) -> Void)?

    /// The active camera capture session.
    private let captureSession = AVCaptureSession()

    /// The preview layer rendering the camera image.
    private var previewLayer: AVCaptureVideoPreviewLayer?

    /// Guards against duplicate callback delivery.
    private var hasDeliveredCode: Bool = false

    /// Serial queue used to run blocking capture session operations.
    private let captureSessionQueue = DispatchQueue(label: "LocalPeerSync.Scanner.CaptureSession")

    /// Configures camera and starts scanning when view loads.
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureCaptureSession()
    }

    /// Resizes preview layer to match view bounds.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    /// Starts capture when the view appears.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureSessionQueue.async { [weak self] in
            guard let self else { return }
            if captureSession.isRunning == false {
                captureSession.startRunning()
            }
        }
    }

    /// Stops capture when the view disappears.
    ///
    /// - Parameter animated: Whether the disappearance is animated.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSessionQueue.async { [weak self] in
            guard let self else { return }
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }

    /// Handles scanned metadata objects and emits the first QR string payload.
    ///
    /// - Parameters:
    ///   - output: The metadata output.
    ///   - metadataObjects: Metadata objects detected in the current frame.
    ///   - connection: The capture connection.
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        _ = output
        _ = connection
        guard hasDeliveredCode == false,
              let qrObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              qrObject.type == .qr,
              let value = qrObject.stringValue
        else {
            return
        }

        hasDeliveredCode = true
        captureSessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
        onCodeScanned?(value)
    }
}

private extension LocalPeerSyncScannerViewController {
    /// Configures camera input, metadata output, and preview layer.
    func configureCaptureSession() {
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput)
        else {
            return
        }

        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(metadataOutput) else {
            return
        }

        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
    }
}
#endif
