//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
@preconcurrency import Network

extension LocalPeerSyncCoordinator {
    /// Returns a readable endpoint string for debug logs.
    ///
    /// - Parameter endpoint: The endpoint to describe.
    /// - Returns: A string representation for logs.
    static func describe(endpoint: NWEndpoint) -> String {
        switch endpoint {
        case let .hostPort(host, port):
            "\(host):\(port)"
        case let .service(name, type, domain, _):
            "service name=\(name) type=\(type) domain=\(domain)"
        default:
            "\(endpoint)"
        }
    }

    /// Handles a newly accepted or created connection.
    ///
    /// - Parameter connection: The wrapped connection.
    func handleNewConnection(_ connection: LocalPeerConnection) {
        localPeerLog("\(Self.logPrefix) Starting message loop for connection")
        let logPrefix = Self.logPrefix
        connection.start { [weak self] result in
            guard let self else {
                localPeerLog("\(logPrefix) Received connection callback but coordinator is unavailable")
                return
            }

            Task { @MainActor in
                switch result {
                case let .success(message):
                    localPeerLog("\(Self.logPrefix) Received message type=\(message.type)")
                    try await self.handleIncomingMessage(message, connection: connection)
                case let .failure(error):
                    localPeerLog("\(Self.logPrefix) Connection failed: \(error.localizedDescription)")
                    connection.stop()
                }
            }
        }
    }

    /// Handles incoming protocol messages.
    ///
    /// - Parameters:
    ///   - message: The incoming message.
    ///   - connection: The source connection.
    /// - Throws: Protocol handling errors.
    func handleIncomingMessage(
        _ message: LocalPeerSyncMessage,
        connection: LocalPeerConnection
    ) async throws {
        guard message.protocolVersion == LocalPeerSyncConfiguration.protocolVersion else {
            let localVersion = LocalPeerSyncConfiguration.protocolVersion
            let remoteVersion = message.protocolVersion
            localPeerLog(
                "\(Self.logPrefix) Incoming message rejected due to protocol mismatch " +
                    "local=\(localVersion) remote=\(remoteVersion)"
            )
            throw LocalPeerSyncCoordinatorError.incompatibleProtocolVersion
        }

        switch message.type {
        case .pairHello:
            try await handlePairHello(message, connection: connection)
        case .pairConfirm:
            try await handlePairConfirm(message, connection: connection)
        case .pairDone:
            try await handlePairDone(message, connection: connection)
        case .syncRequest:
            try await handleSyncRequest(message, connection: connection)
        case .syncResponse:
            try await handleSyncResponse(message, connection: connection)
        case .ack:
            try await handleAck(message, connection: connection)
        case .error:
            localPeerLog("\(Self.logPrefix) Received protocol error message code=\(message.errorCode ?? "n/a")")
            return
        }
    }

    /// Handles pair hello on provider side.
    ///
    /// - Parameters:
    ///   - message: The incoming hello message.
    ///   - connection: The source connection.
    /// - Throws: Protocol validation errors.
    func handlePairHello(
        _ message: LocalPeerSyncMessage,
        connection: LocalPeerConnection
    ) async throws {
        localPeerLog("\(Self.logPrefix) Handling pairHello")
        pruneExpiredPairingSessions(referenceDate: Date())

        guard let sessionId = message.pairingSessionId,
              let session = pairingSessions[sessionId]
        else {
            localPeerLog("\(Self.logPrefix) pairHello rejected: unknown session")
            throw LocalPeerSyncCoordinatorError.invalidPairingSession
        }

        guard session.secret == message.pairingSecret else {
            localPeerLog("\(Self.logPrefix) pairHello rejected: invalid secret")
            throw LocalPeerSyncCoordinatorError.invalidPairingSecret
        }

        let identity = try await identityStore.identity()
        let response = LocalPeerSyncMessage(
            id: UUID(),
            protocolVersion: LocalPeerSyncConfiguration.protocolVersion,
            sentAt: Date(),
            type: .pairConfirm,
            pairingSessionId: session.id,
            pairingSecret: nil,
            peerId: identity.peerId,
            deviceName: localDeviceName,
            publicKeyFingerprint: identity.publicKeyFingerprint,
            sinceTokenData: nil,
            delta: nil,
            ackTokenData: nil,
            errorCode: nil,
            errorMessage: nil
        )

        try await send(response, over: connection)
        localPeerLog("\(Self.logPrefix) Sent pairConfirm for session id=\(session.id.uuidString)")
    }

    /// Handles pair confirm on scanner side.
    ///
    /// - Parameters:
    ///   - message: The incoming confirm message.
    ///   - connection: The source connection.
    /// - Throws: Protocol validation errors.
    func handlePairConfirm(
        _ message: LocalPeerSyncMessage,
        connection: LocalPeerConnection
    ) async throws {
        localPeerLog("\(Self.logPrefix) Handling pairConfirm")
        guard let peerId = message.peerId,
              let deviceName = message.deviceName,
              let fingerprint = message.publicKeyFingerprint
        else {
            localPeerLog("\(Self.logPrefix) pairConfirm rejected: missing peer identity fields")
            throw LocalPeerSyncCoordinatorError.invalidPairingSession
        }

        let record = LocalPeerTrustRecord(
            peerId: peerId,
            deviceName: deviceName,
            publicKeyFingerprint: fingerprint,
            pairedAt: Date(),
            lastSuccessfulSyncAt: nil
        )
        try await trustStore.save(record)
        connections[peerId] = connection
        localPeerLog("\(Self.logPrefix) Stored trusted peer id=\(peerId) name='\(deviceName)'")
        postPeerConnected(peerId: peerId, deviceName: deviceName)

        let done = try await LocalPeerSyncMessage(
            id: UUID(),
            protocolVersion: LocalPeerSyncConfiguration.protocolVersion,
            sentAt: Date(),
            type: .pairDone,
            pairingSessionId: message.pairingSessionId,
            pairingSecret: nil,
            peerId: identityStore.identity().peerId,
            deviceName: localDeviceName,
            publicKeyFingerprint: identityStore.identity().publicKeyFingerprint,
            sinceTokenData: nil,
            delta: nil,
            ackTokenData: nil,
            errorCode: nil,
            errorMessage: nil
        )

        try await send(done, over: connection)
        localPeerLog("\(Self.logPrefix) Sent pairDone to peer=\(peerId)")
    }

    /// Handles pair done on provider side.
    ///
    /// - Parameters:
    ///   - message: The incoming done message.
    ///   - connection: The source connection.
    /// - Throws: Protocol validation errors.
    func handlePairDone(
        _ message: LocalPeerSyncMessage,
        connection: LocalPeerConnection
    ) async throws {
        localPeerLog("\(Self.logPrefix) Handling pairDone")
        guard let sessionId = message.pairingSessionId,
              let peerId = message.peerId,
              let deviceName = message.deviceName,
              let fingerprint = message.publicKeyFingerprint
        else {
            localPeerLog("\(Self.logPrefix) pairDone rejected: missing fields")
            throw LocalPeerSyncCoordinatorError.invalidPairingSession
        }

        pairingSessions.removeValue(forKey: sessionId)
        localPeerLog("\(Self.logPrefix) Pairing session completed and removed id=\(sessionId.uuidString)")

        let record = LocalPeerTrustRecord(
            peerId: peerId,
            deviceName: deviceName,
            publicKeyFingerprint: fingerprint,
            pairedAt: Date(),
            lastSuccessfulSyncAt: nil
        )
        try await trustStore.save(record)
        connections[peerId] = connection
        localPeerLog("\(Self.logPrefix) Peer trusted from pairDone id=\(peerId) name='\(deviceName)'")
        postPeerConnected(peerId: peerId, deviceName: deviceName)
    }

    /// Handles a sync request and responds with a delta.
    ///
    /// - Parameters:
    ///   - message: The incoming request.
    ///   - connection: The target connection.
    func handleSyncRequest(
        _ message: LocalPeerSyncMessage,
        connection: LocalPeerConnection
    ) async throws {
        localPeerLog("\(Self.logPrefix) Handling syncRequest")
        guard let trustedPeer = try await resolveTrustedPeer(
            message: message,
            connection: connection
        )
        else {
            localPeerLog("\(Self.logPrefix) syncRequest rejected: untrusted peer")
            throw LocalPeerSyncCoordinatorError.untrustedPeer
        }
        let peerId = trustedPeer.peerId
        let trustRecord = trustedPeer.record
        connections[peerId] = connection

        #if os(iOS) && !targetEnvironment(macCatalyst)
        guard approvedIncomingSyncPeerIds.remove(peerId) != nil else {
            postIncomingSyncApprovalRequested(peerId: peerId, deviceName: trustRecord.deviceName)
            localPeerLog("\(Self.logPrefix) syncRequest awaiting user approval for peer=\(peerId)")
            return
        }
        #endif

        postSyncActivityChanged(
            peerId: peerId,
            deviceName: trustRecord.deviceName,
            isSyncing: true,
            isIncomingSyncRequest: true
        )
        defer {
            postSyncActivityChanged(
                peerId: peerId,
                deviceName: trustRecord.deviceName,
                isSyncing: false,
                isIncomingSyncRequest: true
            )
        }

        let delta = try await deltaEngine.createDelta(since: message.sinceTokenData)
        let deleteCount = delta.deletes.count
        localPeerLog(
            "\(Self.logPrefix) Created syncResponse delta for peer=\(peerId) " +
                "upserts=\(delta.upserts.count) deletes=\(deleteCount) tokenBytes=\(delta.newTokenData.count)"
        )
        let response = try await LocalPeerSyncMessage(
            id: UUID(),
            protocolVersion: LocalPeerSyncConfiguration.protocolVersion,
            sentAt: Date(),
            type: .syncResponse,
            pairingSessionId: nil,
            pairingSecret: nil,
            peerId: identityStore.identity().peerId,
            deviceName: localDeviceName,
            publicKeyFingerprint: nil,
            sinceTokenData: nil,
            delta: delta,
            ackTokenData: nil,
            errorCode: nil,
            errorMessage: nil
        )

        try await send(response, over: connection)
        localPeerLog("\(Self.logPrefix) Sent syncResponse to peer=\(peerId)")
    }

    /// Handles a sync response by applying the incoming delta.
    ///
    /// - Parameters:
    ///   - message: The incoming response.
    ///   - connection: The source connection.
    func handleSyncResponse(
        _ message: LocalPeerSyncMessage,
        connection: LocalPeerConnection
    ) async throws {
        localPeerLog("\(Self.logPrefix) Handling syncResponse")
        guard let delta = message.delta,
              let trustedPeer = try await resolveTrustedPeer(
                  message: message,
                  connection: connection
              )
        else {
            localPeerLog("\(Self.logPrefix) syncResponse rejected: untrusted peer or missing delta")
            throw LocalPeerSyncCoordinatorError.untrustedPeer
        }
        let peerId = trustedPeer.peerId
        let trustRecord = trustedPeer.record
        connections[peerId] = connection
        postSyncActivityChanged(
            peerId: peerId,
            deviceName: trustRecord.deviceName,
            isSyncing: true,
            isIncomingSyncRequest: false
        )
        defer {
            postSyncActivityChanged(
                peerId: peerId,
                deviceName: trustRecord.deviceName,
                isSyncing: false,
                isIncomingSyncRequest: false
            )
        }

        let deleteCount = delta.deletes.count
        localPeerLog(
            "\(Self.logPrefix) Applying delta from peer=\(peerId) " +
                "upserts=\(delta.upserts.count) deletes=\(deleteCount) tokenBytes=\(delta.newTokenData.count)"
        )
        try await deltaEngine.apply(delta: delta)
        try await updateTransferStatus(peerId: peerId, delta: delta)

        if delta.newTokenData.isEmpty == false {
            try await checkpointStore.save(peerId: peerId, direction: "outgoing", tokenData: delta.newTokenData)
            localPeerLog("\(Self.logPrefix) Saved outgoing checkpoint for peer=\(peerId) bytes=\(delta.newTokenData.count)")
        }

        let ack = try await LocalPeerSyncMessage(
            id: UUID(),
            protocolVersion: LocalPeerSyncConfiguration.protocolVersion,
            sentAt: Date(),
            type: .ack,
            pairingSessionId: nil,
            pairingSecret: nil,
            peerId: identityStore.identity().peerId,
            deviceName: nil,
            publicKeyFingerprint: nil,
            sinceTokenData: nil,
            delta: nil,
            ackTokenData: delta.newTokenData,
            errorCode: nil,
            errorMessage: nil
        )

        try await send(ack, over: connection)
        localPeerLog("\(Self.logPrefix) Sent ack to peer=\(peerId)")
    }

    /// Handles an ack message and persists incoming checkpoint.
    ///
    /// - Parameters:
    ///   - message: The incoming ack message.
    ///   - connection: The source connection.
    func handleAck(_ message: LocalPeerSyncMessage, connection: LocalPeerConnection) async throws {
        localPeerLog("\(Self.logPrefix) Handling ack")
        guard let tokenData = message.ackTokenData,
              tokenData.isEmpty == false,
              let trustedPeer = try await resolveTrustedPeer(message: message, connection: connection)
        else {
            localPeerLog("\(Self.logPrefix) Ignoring ack with missing peer or token")
            return
        }

        let peerId = trustedPeer.peerId
        try await checkpointStore.save(peerId: peerId, direction: "incoming", tokenData: tokenData)
        localPeerLog("\(Self.logPrefix) Saved incoming checkpoint for peer=\(peerId) bytes=\(tokenData.count)")
    }

    /// Sends one message over a wrapped connection.
    ///
    /// - Parameters:
    ///   - message: The outgoing message.
    ///   - connection: The target connection.
    /// - Throws: Any transport error.
    func send(_ message: LocalPeerSyncMessage, over connection: LocalPeerConnection) async throws {
        localPeerLog("\(Self.logPrefix) Sending message type=\(message.type)")
        let logPrefix = Self.logPrefix
        try await withCheckedThrowingContinuation { continuation in
            connection.send(message) { result in
                switch result {
                case .success:
                    localPeerLog("\(logPrefix) Send succeeded for type=\(message.type)")
                    continuation.resume(returning: ())
                case let .failure(error):
                    localPeerLog("\(logPrefix) Send failed for type=\(message.type): \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Removes expired provider-side pairing sessions.
    ///
    /// - Parameter referenceDate: The current date.
    func pruneExpiredPairingSessions(referenceDate: Date) {
        let beforeCount = pairingSessions.count
        pairingSessions = pairingSessions.filter { _, session in
            referenceDate < session.expiresAt
        }
        let removedCount = beforeCount - pairingSessions.count
        if removedCount > 0 {
            localPeerLog("\(Self.logPrefix) Removed \(removedCount) expired pairing session(s)")
        }
    }

    /// Updates persisted trust and transfer stats for a completed sync response.
    ///
    /// - Parameters:
    ///   - peerId: The trusted peer identifier.
    ///   - delta: The applied delta payload.
    func updateTransferStatus(
        peerId: String,
        delta: LocalPeerSyncDelta
    ) async throws {
        let transferDate = Date()
        let payloadBytes = try measurePayloadBytes(delta)
        localPeerLog("\(Self.logPrefix) Updating transfer status for peer=\(peerId) payloadBytes=\(payloadBytes)")
        try await statsStore.addTransfer(peerId: peerId, bytes: payloadBytes, date: transferDate)

        if let currentRecord = try await trustStore.load(peerId: peerId) {
            let updatedRecord = LocalPeerTrustRecord(
                peerId: currentRecord.peerId,
                deviceName: currentRecord.deviceName,
                publicKeyFingerprint: currentRecord.publicKeyFingerprint,
                pairedAt: currentRecord.pairedAt,
                lastSuccessfulSyncAt: transferDate
            )
            try await trustStore.save(updatedRecord)
            localPeerLog("\(Self.logPrefix) Updated lastSuccessfulSyncAt for peer=\(peerId)")
        }
    }

    /// Measures the encoded byte size of a delta payload.
    ///
    /// - Parameter delta: The delta payload.
    /// - Returns: The encoded payload size in bytes.
    func measurePayloadBytes(_ delta: LocalPeerSyncDelta) throws -> Int64 {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(delta)
        return Int64(data.count)
    }

    /// Posts an event after a trusted peer was connected.
    ///
    /// - Parameters:
    ///   - peerId: The connected peer identifier.
    ///   - deviceName: The connected peer name.
    func postPeerConnected(peerId: String, deviceName: String) {
        NotificationCenter.default.post(
            name: LocalPeerSyncNotifications.peerConnected,
            object: nil,
            userInfo: [
                LocalPeerSyncNotifications.peerIdKey: peerId,
                LocalPeerSyncNotifications.deviceNameKey: deviceName
            ]
        )
        localPeerLog("\(Self.logPrefix) Posted peerConnected event for peer=\(peerId)")
    }

    /// Posts an event when sync activity starts or ends for one peer.
    ///
    /// - Parameters:
    ///   - peerId: The active peer identifier.
    ///   - deviceName: The active peer display name.
    ///   - isSyncing: Indicates whether sync is currently running.
    ///   - isIncomingSyncRequest: Indicates whether this activity belongs to an incoming sync request.
    func postSyncActivityChanged(
        peerId: String,
        deviceName: String,
        isSyncing: Bool,
        isIncomingSyncRequest: Bool
    ) {
        NotificationCenter.default.post(
            name: LocalPeerSyncNotifications.syncActivityChanged,
            object: nil,
            userInfo: [
                LocalPeerSyncNotifications.peerIdKey: peerId,
                LocalPeerSyncNotifications.deviceNameKey: deviceName,
                LocalPeerSyncNotifications.isSyncingKey: isSyncing,
                LocalPeerSyncNotifications.isIncomingSyncRequestKey: isIncomingSyncRequest
            ]
        )
        localPeerLog("\(Self.logPrefix) Posted syncActivityChanged for peer=\(peerId) isSyncing=\(isSyncing)")
    }

    /// Posts an event requesting user approval for one incoming sync request.
    ///
    /// - Parameters:
    ///   - peerId: The requesting trusted peer identifier.
    ///   - deviceName: The requesting trusted peer name.
    func postIncomingSyncApprovalRequested(peerId: String, deviceName: String) {
        NotificationCenter.default.post(
            name: LocalPeerSyncNotifications.incomingSyncApprovalRequested,
            object: nil,
            userInfo: [
                LocalPeerSyncNotifications.peerIdKey: peerId,
                LocalPeerSyncNotifications.deviceNameKey: deviceName
            ]
        )
        localPeerLog("\(Self.logPrefix) Posted incomingSyncApprovalRequested for peer=\(peerId)")
    }

    /// Resolves a trusted peer for one sync message, including peer-id reconciliation.
    ///
    /// - Parameters:
    ///   - message: The incoming sync message.
    ///   - connection: The connection that delivered the message.
    /// - Returns: A trusted peer tuple or `nil` when no trusted mapping exists.
    func resolveTrustedPeer(
        message: LocalPeerSyncMessage,
        connection: LocalPeerConnection
    ) async throws -> (peerId: String, record: LocalPeerTrustRecord)? {
        if let incomingPeerId = message.peerId,
           let record = try await trustStore.load(peerId: incomingPeerId)
        {
            return (incomingPeerId, record)
        }

        if let incomingPeerId = message.peerId,
           let mappedPeerId = connections.first(where: { $0.value === connection })?.key,
           let mappedRecord = try await trustStore.load(peerId: mappedPeerId)
        {
            return try await reconcileTrustedPeerId(
                from: TrustedPeerMigrationSource(
                    peerId: mappedPeerId,
                    record: mappedRecord
                ),
                to: incomingPeerId,
                incomingDeviceName: message.deviceName,
                connection: connection
            )
        }

        guard let incomingPeerId = message.peerId,
              let incomingDeviceName = message.deviceName
        else {
            return nil
        }

        let nameMatches = try await trustStore.all().filter { record in
            record.deviceName == incomingDeviceName
        }
        guard nameMatches.count == 1, let match = nameMatches.first else {
            return nil
        }

        return try await reconcileTrustedPeerId(
            from: TrustedPeerMigrationSource(
                peerId: match.peerId,
                record: match
            ),
            to: incomingPeerId,
            incomingDeviceName: incomingDeviceName,
            connection: connection
        )
    }

    /// Reconciles one trusted peer record when a known device reports a new peer id.
    ///
    /// This bundles the existing trusted peer identifier and record for migration.
    struct TrustedPeerMigrationSource {
        /// The currently stored trusted peer id.
        let peerId: String
        /// The trusted fallback record tied to the current peer id.
        let record: LocalPeerTrustRecord
    }

    /// Reconciles one trusted peer record when a known device reports a new peer id.
    ///
    /// - Parameters:
    ///   - source: The source trusted peer identifier and record.
    ///   - targetPeerId: The incoming peer id from the network message.
    ///   - incomingDeviceName: The optional incoming device name.
    ///   - connection: The active network connection.
    /// - Returns: The resolved trusted peer tuple.
    func reconcileTrustedPeerId(
        from source: TrustedPeerMigrationSource,
        to targetPeerId: String,
        incomingDeviceName: String?,
        connection: LocalPeerConnection
    ) async throws -> (peerId: String, record: LocalPeerTrustRecord) {
        let sourcePeerId = source.peerId
        let fallbackRecord = source.record
        if sourcePeerId == targetPeerId {
            connections[sourcePeerId] = connection
            return (sourcePeerId, fallbackRecord)
        }

        let resolvedDeviceName = incomingDeviceName ?? fallbackRecord.deviceName
        let migratedRecord = LocalPeerTrustRecord(
            peerId: targetPeerId,
            deviceName: resolvedDeviceName,
            publicKeyFingerprint: fallbackRecord.publicKeyFingerprint,
            pairedAt: fallbackRecord.pairedAt,
            lastSuccessfulSyncAt: fallbackRecord.lastSuccessfulSyncAt
        )

        try await trustStore.remove(peerId: sourcePeerId)
        try await trustStore.save(migratedRecord)
        connections.removeValue(forKey: sourcePeerId)
        connections[targetPeerId] = connection

        localPeerLog(
            "\(Self.logPrefix) Reconciled trusted peer id from \(sourcePeerId) to \(targetPeerId) " +
                "for device '\(resolvedDeviceName)'"
        )
        return (targetPeerId, migratedRecord)
    }
}
