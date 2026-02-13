//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation
@preconcurrency import Network
import Security
#if os(iOS)
import UIKit
#endif

/// Defines errors emitted by the local peer sync coordinator.
enum LocalPeerSyncCoordinatorError: Error {
    /// Indicates that a scanned QR code payload is malformed.
    case invalidQRCodePayload

    /// Indicates that the pairing payload has expired.
    case expiredPairingPayload

    /// Indicates that no active pairing session matches the incoming hello.
    case invalidPairingSession

    /// Indicates that a required secret does not match.
    case invalidPairingSecret

    /// Indicates that the peer is not trusted.
    case untrustedPeer

    /// Indicates that the remote protocol version is unsupported.
    case incompatibleProtocolVersion
}

/// Represents one pairing session on the provider side.
struct LocalPairingSession: Sendable {
    /// The session identifier embedded into the QR payload.
    let id: UUID

    /// The one-time pairing secret.
    let secret: String

    /// The creation timestamp.
    let createdAt: Date

    /// The expiration timestamp.
    let expiresAt: Date
}

/// Represents the current synchronization status shown in the iOS intro screen.
struct LocalPeerSyncStatusSnapshot: Sendable {
    /// Indicates whether at least one trusted peer exists.
    let hasTrustedPeer: Bool

    /// The number of trusted peers.
    let peerCount: Int

    /// The most recently active peer name.
    let lastPeerName: String?

    /// The timestamp of the most recent transfer.
    let lastTransferAt: Date?

    /// The cumulative synchronized payload size in bytes.
    let totalSyncedBytes: Int64

    /// Returns an empty status state.
    static var empty: LocalPeerSyncStatusSnapshot {
        LocalPeerSyncStatusSnapshot(
            hasTrustedPeer: false,
            peerCount: 0,
            lastPeerName: nil,
            lastTransferAt: nil,
            totalSyncedBytes: 0
        )
    }
}

/// Coordinates pairing, trust, transport, and bidirectional delta sync.
@MainActor
final class LocalPeerSyncCoordinator {
    /// Shared coordinator instance configured at bootstrap time.
    static var shared: LocalPeerSyncCoordinator?

    /// Handles Bonjour advertise and discovery.
    let transport: LocalPeerBonjourTransport

    /// Builds and applies Core Data deltas.
    let deltaEngine: LocalPeerSyncDeltaEngine

    /// Persists trusted peers in Keychain.
    let trustStore: LocalPeerTrustStore

    /// Persists directional persistent-history checkpoints.
    let checkpointStore: LocalPeerHistoryCheckpointStore

    /// Persists local device identity used in pairing and sync.
    let identityStore: LocalPeerIdentityStore

    /// Persists aggregated transfer statistics.
    let statsStore: LocalPeerSyncStatsStore

    /// Stores active provider-side pairing sessions.
    var pairingSessions: [UUID: LocalPairingSession] = [:]

    /// Stores active connections keyed by peer id.
    var connections: [String: LocalPeerConnection] = [:]

    /// Stores the default local device name used for pairing.
    let localDeviceName: String

    /// Stores the running browser state.
    var isBrowsing: Bool = false

    /// Stores whether hosting has already started.
    var isHosting: Bool = false

    /// Stores the currently active reconnect timeout task.
    var reconnectTimeoutTask: Task<Void, Never>?

    /// Stores one-time approvals for incoming sync requests keyed by peer id.
    var approvedIncomingSyncPeerIds: Set<String> = []

    /// The static log prefix used by coordinator messages.
    static var logPrefix: String {
        "[LOCAL SYNC][\(platformName)][Coordinator]"
    }

    /// Creates a coordinator configured with app dependencies.
    ///
    /// - Parameters:
    ///   - container: The persistent container.
    ///   - transport: The network transport abstraction.
    ///   - trustStore: The trust store implementation.
    ///   - checkpointStore: The checkpoint store implementation.
    ///   - identityStore: The local identity store.
    init(
        container: NSPersistentContainer,
        transport: LocalPeerBonjourTransport,
        trustStore: LocalPeerTrustStore,
        checkpointStore: LocalPeerHistoryCheckpointStore,
        identityStore: LocalPeerIdentityStore,
        statsStore: LocalPeerSyncStatsStore,
        localDeviceName: String
    ) {
        self.transport = transport
        deltaEngine = LocalPeerSyncDeltaEngine(persistentContainer: container)
        self.trustStore = trustStore
        self.checkpointStore = checkpointStore
        self.identityStore = identityStore
        self.statsStore = statsStore
        self.localDeviceName = localDeviceName
    }

    /// Configures the shared coordinator using the provided persistent container.
    ///
    /// - Parameter container: The persistent container used for delta sync.
    static func configureShared(container: NSPersistentContainer) {
        localPeerLog("\(logPrefix) Configuring shared coordinator instance")
        let coordinator = LocalPeerSyncCoordinator(
            container: container,
            transport: LocalPeerBonjourTransport(),
            trustStore: LocalPeerTrustStore(),
            checkpointStore: LocalPeerHistoryCheckpointStore(),
            identityStore: LocalPeerIdentityStore(),
            statsStore: LocalPeerSyncStatsStore(),
            localDeviceName: defaultDeviceName
        )
        shared = coordinator
        localPeerLog("\(logPrefix) Shared coordinator ready for device '\(defaultDeviceName)'")
        Task { @MainActor in
            await coordinator.runStartupTrustMaintenance()
        }
    }

    /// Returns the platform-specific default device name.
    private static var defaultDeviceName: String {
        #if os(iOS)
        return UIDevice.current.name
        #else
        return Host.current().localizedName ?? "Device"
        #endif
    }

    /// Returns the current platform label used for logging.
    private static var platformName: String {
        #if os(iOS)
        "iOS"
        #elseif os(macOS)
        "macOS"
        #else
        "Unknown"
        #endif
    }

    /// Creates a new pairing session and returns the QR payload.
    ///
    /// - Returns: A payload that can be converted to QR code data.
    func createPairingPayload() -> PairingQRCodePayload {
        pruneExpiredPairingSessions(referenceDate: Date())
        let now = Date()
        let session = LocalPairingSession(
            id: UUID(),
            secret: UUID().uuidString.replacingOccurrences(of: "-", with: ""),
            createdAt: now,
            expiresAt: now.addingTimeInterval(LocalPeerSyncConfiguration.pairingLifetimeInSeconds)
        )
        pairingSessions[session.id] = session
        let sessionExpiry = session.expiresAt.ISO8601Format()
        localPeerLog(
            "\(Self.logPrefix) Created pairing session id=\(session.id.uuidString) " +
                "expiresAt=\(sessionExpiry) activeSessions=\(pairingSessions.count)"
        )

        return PairingQRCodePayload(
            pairingSessionId: session.id,
            bonjourServiceType: LocalPeerSyncConfiguration.bonjourServiceType,
            expectedPeerDeviceId: localDeviceName,
            pairingSecret: session.secret,
            protocolVersion: LocalPeerSyncConfiguration.protocolVersion,
            expiresAt: session.expiresAt
        )
    }

    /// Encodes a pairing payload into a compact Base64 string for QR rendering.
    ///
    /// - Parameter payload: The payload to encode.
    /// - Returns: Base64 encoded JSON payload.
    /// - Throws: Any JSON encoding error.
    func makeQRCodeString(from payload: PairingQRCodePayload) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        localPeerLog(
            "\(Self.logPrefix) Encoded QR payload for session id=\(payload.pairingSessionId.uuidString) bytes=\(data.count)"
        )
        return data.base64EncodedString()
    }

    /// Parses a scanned QR code Base64 payload.
    ///
    /// - Parameter rawValue: The scanned payload string.
    /// - Returns: The decoded payload model.
    /// - Throws: `LocalPeerSyncCoordinatorError` for malformed input.
    func parseQRCodePayload(_ rawValue: String) throws -> PairingQRCodePayload {
        localPeerLog("\(Self.logPrefix) Parsing scanned QR payload with characters=\(rawValue.count)")
        guard let data = Data(base64Encoded: rawValue) else {
            localPeerLog("\(Self.logPrefix) QR payload parsing failed: invalid Base64")
            throw LocalPeerSyncCoordinatorError.invalidQRCodePayload
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(PairingQRCodePayload.self, from: data)
            guard payload.isValid() else {
                localPeerLog("\(Self.logPrefix) QR payload parsing failed: payload expired")
                throw LocalPeerSyncCoordinatorError.expiredPairingPayload
            }
            guard payload.protocolVersion == LocalPeerSyncConfiguration.protocolVersion else {
                let localVersion = LocalPeerSyncConfiguration.protocolVersion
                let remoteVersion = payload.protocolVersion
                localPeerLog(
                    "\(Self.logPrefix) QR payload parsing failed: protocol mismatch " +
                        "local=\(localVersion) remote=\(remoteVersion)"
                )
                throw LocalPeerSyncCoordinatorError.incompatibleProtocolVersion
            }
            localPeerLog(
                "\(Self.logPrefix) Parsed QR payload session id=\(payload.pairingSessionId.uuidString) expiresAt=\(payload.expiresAt.ISO8601Format())"
            )
            return payload
        } catch let error as LocalPeerSyncCoordinatorError {
            throw error
        } catch {
            localPeerLog("\(Self.logPrefix) QR payload parsing failed: \(error.localizedDescription)")
            throw LocalPeerSyncCoordinatorError.invalidQRCodePayload
        }
    }

    /// Starts discovery and initiates the scanner-side pairing handshake.
    ///
    /// - Parameter payload: The decoded QR payload.
    /// - Throws: Transport and protocol errors.
    func pairWithPeer(using payload: PairingQRCodePayload) async throws {
        guard isBrowsing == false else {
            localPeerLog("\(Self.logPrefix) pairWithPeer ignored because browsing is already active")
            return
        }
        isBrowsing = true
        let logPrefix = Self.logPrefix
        localPeerLog("\(Self.logPrefix) Starting browse for session id=\(payload.pairingSessionId.uuidString)")

        try transport.startBrowsing { [weak self] endpoint in
            guard let self else {
                localPeerLog("\(logPrefix) Browse result ignored because coordinator is unavailable")
                return
            }
            Task { @MainActor in
                guard self.isBrowsing else {
                    return
                }

                if self.shouldSkipEndpoint(
                    endpoint,
                    expectedPeerName: payload.expectedPeerDeviceId
                ) {
                    let expectedPeer = payload.expectedPeerDeviceId ?? "nil"
                    localPeerLog(
                        "\(Self.logPrefix) Ignoring endpoint \(Self.describe(endpoint: endpoint)) " +
                            "for localDevice='\(self.localDeviceName)' expectedPeer='\(expectedPeer)'"
                    )
                    return
                }

                self.isBrowsing = false
                self.transport.stopBrowsing()
                localPeerLog("\(Self.logPrefix) Discovered endpoint \(Self.describe(endpoint: endpoint)); attempting connection")

                let connection = self.transport.connect(to: endpoint)
                self.handleNewConnection(connection)

                let identity = try await self.identityStore.identity()
                let hello = LocalPeerSyncMessage(
                    id: UUID(),
                    protocolVersion: LocalPeerSyncConfiguration.protocolVersion,
                    sentAt: Date(),
                    type: .pairHello,
                    pairingSessionId: payload.pairingSessionId,
                    pairingSecret: payload.pairingSecret,
                    peerId: identity.peerId,
                    deviceName: self.localDeviceName,
                    publicKeyFingerprint: identity.publicKeyFingerprint,
                    sinceTokenData: nil,
                    delta: nil,
                    ackTokenData: nil,
                    errorCode: nil,
                    errorMessage: nil
                )
                localPeerLog("\(Self.logPrefix) Sending pairHello to discovered endpoint")
                try await self.send(hello, over: connection)
            }
        }
    }

    /// Returns whether a discovered endpoint should be ignored for the current pairing payload.
    ///
    /// - Parameters:
    ///   - endpoint: The discovered Bonjour endpoint.
    ///   - expectedPeerName: The expected provider service name from QR payload.
    /// - Returns: `true` when endpoint should be skipped.
    private func shouldSkipEndpoint(
        _ endpoint: NWEndpoint,
        expectedPeerName: String?
    ) -> Bool {
        guard case let .service(name, _, _, _) = endpoint else {
            return false
        }
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedLocalName = localDeviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedName == normalizedLocalName {
            return true
        }
        guard let expectedPeerName else {
            return false
        }
        let normalizedExpectedPeer = expectedPeerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalizedName != normalizedExpectedPeer
    }

    /// Triggers one bidirectional sync cycle with a trusted peer.
    ///
    /// - Parameter peerId: The trusted peer identifier.
    /// - Throws: `LocalPeerSyncCoordinatorError` when trust is missing.
    func syncNow(with peerId: String) async throws {
        localPeerLog("\(Self.logPrefix) Requested syncNow for peer=\(peerId)")
        guard let trustRecord = try await trustStore.load(peerId: peerId) else {
            localPeerLog("\(Self.logPrefix) syncNow aborted: peer=\(peerId) is not trusted")
            throw LocalPeerSyncCoordinatorError.untrustedPeer
        }
        let resolved = try await resolveActiveConnection(
            requestedPeerId: peerId,
            requestedDeviceName: trustRecord.deviceName
        )
        let resolvedPeerId = resolved.peerId
        let connection = resolved.connection

        postSyncActivityChanged(
            peerId: resolvedPeerId,
            deviceName: trustRecord.deviceName,
            isSyncing: true,
            isIncomingSyncRequest: false
        )
        defer {
            postSyncActivityChanged(
                peerId: resolvedPeerId,
                deviceName: trustRecord.deviceName,
                isSyncing: false,
                isIncomingSyncRequest: false
            )
        }

        let checkpoint = try await checkpointStore.load(peerId: resolvedPeerId, direction: "outgoing")
        let identity = try await identityStore.identity()
        let request = LocalPeerSyncMessage(
            id: UUID(),
            protocolVersion: LocalPeerSyncConfiguration.protocolVersion,
            sentAt: Date(),
            type: .syncRequest,
            pairingSessionId: nil,
            pairingSecret: nil,
            peerId: identity.peerId,
            deviceName: localDeviceName,
            publicKeyFingerprint: nil,
            sinceTokenData: checkpoint?.tokenData,
            delta: nil,
            ackTokenData: nil,
            errorCode: nil,
            errorMessage: nil
        )

        localPeerLog(
            "\(Self.logPrefix) Sending syncRequest to peer=\(resolvedPeerId) checkpointBytes=\(checkpoint?.tokenData.count ?? 0)"
        )
        try await send(request, over: connection)
    }

    /// Resolves one active connection for a requested trusted peer id.
    ///
    /// - Parameters:
    ///   - requestedPeerId: The requested trusted peer identifier.
    ///   - requestedDeviceName: The trusted peer device name.
    /// - Returns: The resolved peer identifier with an active connection.
    /// - Throws: `LocalPeerSyncCoordinatorError` when no active connection exists.
    private func resolveActiveConnection(
        requestedPeerId: String,
        requestedDeviceName: String
    ) async throws -> (peerId: String, connection: LocalPeerConnection) {
        if let directConnection = connections[requestedPeerId] {
            return (requestedPeerId, directConnection)
        }

        for (candidatePeerId, candidateConnection) in connections {
            guard let candidateTrust = try await trustStore.load(peerId: candidatePeerId) else {
                continue
            }
            if candidateTrust.deviceName == requestedDeviceName {
                localPeerLog(
                    "\(Self.logPrefix) syncNow remapped peer id from \(requestedPeerId) to \(candidatePeerId) for device '\(requestedDeviceName)'"
                )
                return (candidatePeerId, candidateConnection)
            }
        }

        if connections.count == 1, let fallback = connections.first {
            localPeerLog(
                "\(Self.logPrefix) syncNow using only active connection peer=\(fallback.key) for requested peer=\(requestedPeerId)"
            )
            return (fallback.key, fallback.value)
        }

        localPeerLog("\(Self.logPrefix) syncNow aborted: no active connection for peer=\(requestedPeerId)")
        throw LocalPeerSyncCoordinatorError.untrustedPeer
    }

    /// Approves one pending incoming sync request for a trusted peer.
    ///
    /// - Parameter peerId: The trusted peer identifier approved by the user.
    func approveIncomingSync(for peerId: String) {
        approvedIncomingSyncPeerIds.insert(peerId)
        localPeerLog("\(Self.logPrefix) Approved next incoming sync for peer=\(peerId)")
    }
}

extension LocalPeerSyncCoordinator {
    /// Starts hosting and accepting incoming sync connections.
    ///
    /// - Throws: `LocalPeerTransportError` when listener creation fails.
    func startHosting() throws(LocalPeerTransportError) {
        guard isHosting == false else {
            localPeerLog("\(Self.logPrefix) startHosting ignored because hosting is already active")
            return
        }
        let logPrefix = Self.logPrefix
        localPeerLog("\(Self.logPrefix) Starting host listener with Bonjour name '\(localDeviceName)'")
        try transport.startListening(serviceName: localDeviceName) { [weak self] connection in
            guard let self else {
                localPeerLog("\(logPrefix) Received incoming connection but coordinator is unavailable")
                connection.stop()
                return
            }
            localPeerLog("\(logPrefix) Incoming connection accepted")
            Task { @MainActor in
                self.handleNewConnection(connection)
            }
        }
        isHosting = true
        localPeerLog("\(Self.logPrefix) Host listener started")
    }

    /// Stops all active transport resources and connections.
    func stop() {
        localPeerLog("\(Self.logPrefix) Stopping coordinator and clearing \(connections.count) active connection(s)")
        connections.values.forEach { $0.stop() }
        connections.removeAll()
        approvedIncomingSyncPeerIds.removeAll()
        reconnectTimeoutTask?.cancel()
        reconnectTimeoutTask = nil
        transport.stop()
        isBrowsing = false
        isHosting = false
        localPeerLog("\(Self.logPrefix) Coordinator stopped")
    }

    /// Reconnects to the most recently used trusted peer without a new QR pairing.
    ///
    /// - Throws: Transport errors or trust validation errors.
    func reconnectToTrustedPeer() async throws {
        if isBrowsing {
            localPeerLog("\(Self.logPrefix) reconnectToTrustedPeer restarting active browse session")
            isBrowsing = false
            reconnectTimeoutTask?.cancel()
            reconnectTimeoutTask = nil
            transport.stopBrowsing()
        }
        let peers = try await trustStore.all()
        guard let peer = peers.sorted(by: { lhs, rhs in
            let leftDate = lhs.lastSuccessfulSyncAt ?? lhs.pairedAt
            let rightDate = rhs.lastSuccessfulSyncAt ?? rhs.pairedAt
            return leftDate > rightDate
        }).first else {
            localPeerLog("\(Self.logPrefix) reconnectToTrustedPeer aborted: no trusted peer available")
            throw LocalPeerSyncCoordinatorError.untrustedPeer
        }

        do {
            try startHosting()
        } catch {
            localPeerLog("\(Self.logPrefix) reconnectToTrustedPeer hosting not started: \(error.localizedDescription)")
        }

        isBrowsing = true
        startReconnectTimeout(for: peer)
        let logPrefix = Self.logPrefix
        localPeerLog("\(Self.logPrefix) Reconnecting to trusted peer id=\(peer.peerId) name='\(peer.deviceName)'")

        try transport.startBrowsing { [weak self] endpoint in
            guard let self else {
                localPeerLog("\(logPrefix) Trusted reconnect result ignored because coordinator is unavailable")
                return
            }
            Task { @MainActor in
                guard self.isBrowsing else {
                    return
                }
                guard self.isExpectedTrustedEndpoint(endpoint, expectedDeviceName: peer.deviceName) else {
                    return
                }

                self.isBrowsing = false
                self.reconnectTimeoutTask?.cancel()
                self.reconnectTimeoutTask = nil
                self.transport.stopBrowsing()
                localPeerLog("\(Self.logPrefix) Reconnect found endpoint \(Self.describe(endpoint: endpoint))")

                let connection = self.transport.connect(to: endpoint)
                self.connections[peer.peerId] = connection
                self.handleNewConnection(connection)
                self.postPeerConnected(peerId: peer.peerId, deviceName: peer.deviceName)
            }
        }
    }

    /// Returns whether a discovered endpoint matches one trusted peer device name.
    ///
    /// - Parameters:
    ///   - endpoint: The discovered Bonjour endpoint.
    ///   - expectedDeviceName: The trusted peer device name.
    /// - Returns: `true` when endpoint should be used for reconnect.
    private func isExpectedTrustedEndpoint(
        _ endpoint: NWEndpoint,
        expectedDeviceName: String
    ) -> Bool {
        guard case let .service(name, _, _, _) = endpoint else {
            return false
        }
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedLocalName = localDeviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedName == normalizedLocalName {
            return false
        }
        let normalizedExpectedName = expectedDeviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalizedName == normalizedExpectedName
    }

    /// Starts a timeout that stops reconnect browsing when no endpoint was found.
    ///
    /// - Parameter peer: The trusted peer currently being reconnected.
    private func startReconnectTimeout(for peer: LocalPeerTrustRecord) {
        reconnectTimeoutTask?.cancel()
        reconnectTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard let self, isBrowsing else {
                return
            }
            isBrowsing = false
            transport.stopBrowsing()
            reconnectTimeoutTask = nil
            localPeerLog(
                "\(Self.logPrefix) Reconnect timed out for peer id=\(peer.peerId) name='\(peer.deviceName)'"
            )
        }
    }

    /// Returns the current persisted status summary for local peer sync.
    ///
    /// - Returns: A snapshot for UI display.
    func currentStatusSnapshot() async -> LocalPeerSyncStatusSnapshot {
        do {
            let peers = try await trustStore.all()
            guard peers.isEmpty == false else {
                localPeerLog("\(Self.logPrefix) Status snapshot: no trusted peers")
                return .empty
            }

            var totalBytes: Int64 = 0
            var latestTransferDate: Date?
            var latestPeerName: String?

            for peer in peers {
                if let stats = try await statsStore.load(peerId: peer.peerId) {
                    totalBytes += stats.totalSyncedBytes
                    if let transferDate = stats.lastTransferAt,
                       latestTransferDate == nil || transferDate > (latestTransferDate ?? .distantPast)
                    {
                        latestTransferDate = transferDate
                        latestPeerName = peer.deviceName
                    }
                }
            }

            let fallbackLatest = peers
                .compactMap { record -> (String, Date)? in
                    guard let lastSync = record.lastSuccessfulSyncAt else { return nil }
                    return (record.deviceName, lastSync)
                }
                .max(by: { $0.1 < $1.1 })

            return LocalPeerSyncStatusSnapshot(
                hasTrustedPeer: true,
                peerCount: peers.count,
                lastPeerName: latestPeerName ?? fallbackLatest?.0,
                lastTransferAt: latestTransferDate ?? fallbackLatest?.1,
                totalSyncedBytes: totalBytes
            )
        } catch {
            localPeerLog("\(Self.logPrefix) Status snapshot loading failed: \(error.localizedDescription)")
            return .empty
        }
    }

    /// Removes all persisted local peer sync trust, checkpoint, stats, and identity data.
    func forgetAllPeerSyncData() async {
        stop()
        pairingSessions.removeAll()

        do {
            let peers = try await trustStore.all()
            for peer in peers {
                try await checkpointStore.removeAll(peerId: peer.peerId)
            }
            try await trustStore.removeAll()
            await checkpointStore.removeAll()
            await statsStore.removeAll()
            try await identityStore.resetIdentity()
            localPeerLog("\(Self.logPrefix) Cleared all local peer sync data")
        } catch {
            localPeerLog("\(Self.logPrefix) Failed to clear local peer sync data: \(error.localizedDescription)")
        }
    }
}

/// Persists local peer identity in Keychain.
actor LocalPeerIdentityStore {
    /// The keychain service identifier.
    private let service: String

    /// The keychain account key.
    private let account: String

    /// Caches the loaded local identity for stable message composition.
    private var cachedIdentity: LocalIdentity?

    /// Creates a local identity store.
    ///
    /// - Parameters:
    ///   - service: The keychain service.
    ///   - account: The keychain account.
    init(
        service: String = "com.jandamerau.worktime.localpeersync",
        account: String = "local-identity"
    ) {
        self.service = service
        self.account = account
    }

    /// Returns the local peer identity, creating one when missing.
    ///
    /// - Returns: The identity model.
    /// - Throws: `LocalPeerSyncStoreError` for keychain failures.
    func identity() throws(LocalPeerSyncStoreError) -> (peerId: String, publicKeyFingerprint: String) {
        if let cachedIdentity {
            return (cachedIdentity.peerId, cachedIdentity.publicKeyFingerprint)
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let identity = try? JSONDecoder().decode(LocalIdentity.self, from: data)
        {
            cachedIdentity = identity
            return (identity.peerId, identity.publicKeyFingerprint)
        }

        if status != errSecItemNotFound, status != errSecSuccess {
            throw .keychainFailure(status)
        }

        let identity = LocalIdentity.newIdentity()

        let data: Data
        do {
            data = try JSONEncoder().encode(identity)
        } catch {
            throw .invalidEncoding
        }

        if status == errSecSuccess {
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw .keychainFailure(updateStatus)
            }
            cachedIdentity = identity
            return (identity.peerId, identity.publicKeyFingerprint)
        }

        var insert = query
        insert[kSecValueData as String] = data
        let addStatus = SecItemAdd(insert as CFDictionary, nil)
        if addStatus == errSecDuplicateItem {
            var retryResult: CFTypeRef?
            let retryStatus = SecItemCopyMatching(query as CFDictionary, &retryResult)
            if retryStatus == errSecSuccess,
               let retryData = retryResult as? Data,
               let retryIdentity = try? JSONDecoder().decode(LocalIdentity.self, from: retryData)
            {
                cachedIdentity = retryIdentity
                return (retryIdentity.peerId, retryIdentity.publicKeyFingerprint)
            }
            throw .keychainFailure(retryStatus)
        }

        guard addStatus == errSecSuccess else {
            throw .keychainFailure(addStatus)
        }

        cachedIdentity = identity
        return (identity.peerId, identity.publicKeyFingerprint)
    }

    /// Removes the persisted local identity from keychain and clears the in-memory cache.
    ///
    /// - Throws: `LocalPeerSyncStoreError` if keychain deletion fails.
    func resetIdentity() throws(LocalPeerSyncStoreError) {
        cachedIdentity = nil

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            return
        }

        throw .keychainFailure(status)
    }
}

private struct LocalIdentity: Codable {
    /// The unique peer id.
    let peerId: String

    /// The pseudo-fingerprint used for peer pinning.
    let publicKeyFingerprint: String

    /// Creates a fresh local identity model.
    ///
    /// - Returns: A new local identity with unique peer and fingerprint values.
    static func newIdentity() -> LocalIdentity {
        LocalIdentity(
            peerId: UUID().uuidString.lowercased(),
            publicKeyFingerprint: UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        )
    }
}
