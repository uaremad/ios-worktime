//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
@preconcurrency import Network

/// Namespaces transport components used for local peer sync.
enum LocalPeerSyncTransport {}

/// Defines transport errors for local peer networking.
enum LocalPeerTransportError: Error {
    /// Indicates that the listener failed to start.
    case listenerStartFailed

    /// Indicates that the browser failed to start.
    case browserStartFailed

    /// Indicates that the connection is not ready.
    case connectionNotReady

    /// Indicates that incoming frame data is malformed.
    case invalidFrame
}

/// Handles framed message IO for one network connection.
final class LocalPeerConnection {
    /// The underlying network connection.
    private let connection: NWConnection

    /// The queue used by network callbacks.
    private let queue: DispatchQueue

    /// The static log prefix used by connection messages.
    private static let logPrefix = "[LOCAL SYNC][Connection]"

    /// Creates a connection wrapper.
    ///
    /// - Parameters:
    ///   - connection: The network connection.
    ///   - queue: The callback queue.
    init(connection: NWConnection, queue: DispatchQueue = DispatchQueue(label: "LocalPeerSync.Connection")) {
        self.connection = connection
        self.queue = queue
    }

    /// Starts the connection and read loop.
    ///
    /// - Parameter onMessage: Called for each decoded message.
    func start(onMessage: @escaping @Sendable (Result<LocalPeerSyncMessage, Error>) -> Void) {
        connection.stateUpdateHandler = { state in
            localPeerLog("\(Self.logPrefix) State changed to \(state)")
            if case let .failed(error) = state {
                localPeerLog("\(Self.logPrefix) State failed with error: \(error.localizedDescription)")
                onMessage(.failure(error))
            }
        }

        localPeerLog("\(Self.logPrefix) Starting connection")
        connection.start(queue: queue)
        receiveLength(onMessage: onMessage)
    }

    /// Stops the connection immediately.
    func stop() {
        localPeerLog("\(Self.logPrefix) Cancelling connection")
        connection.cancel()
    }

    /// Sends one protocol message over the framed connection.
    ///
    /// - Parameters:
    ///   - message: The message to send.
    ///   - completion: Called when sending completes.
    func send(
        _ message: LocalPeerSyncMessage,
        completion: @escaping @Sendable (Result<Void, Error>) -> Void
    ) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let payload: Data
        do {
            payload = try encoder.encode(message)
        } catch {
            localPeerLog("\(Self.logPrefix) Encoding failed for message type=\(message.type): \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        var frame = Data()
        var length = UInt32(payload.count).bigEndian
        withUnsafeBytes(of: &length) { buffer in
            frame.append(contentsOf: buffer)
        }
        frame.append(payload)

        localPeerLog("\(Self.logPrefix) Sending framed message type=\(message.type) payloadBytes=\(payload.count)")
        connection.send(content: frame, completion: .contentProcessed { error in
            if let error {
                localPeerLog("\(Self.logPrefix) Send failed for type=\(message.type): \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                localPeerLog("\(Self.logPrefix) Send completed for type=\(message.type)")
                completion(.success(()))
            }
        })
    }
}

private extension LocalPeerConnection {
    /// Receives the frame header and schedules payload reading.
    ///
    /// - Parameter onMessage: Called for each decoded message.
    func receiveLength(onMessage: @escaping @Sendable (Result<LocalPeerSyncMessage, Error>) -> Void) {
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] data, _, isComplete, error in
            guard let self else {
                return
            }

            if let error {
                localPeerLog("\(Self.logPrefix) Receive header failed: \(error.localizedDescription)")
                onMessage(.failure(error))
                return
            }

            if isComplete {
                localPeerLog("\(Self.logPrefix) Receive header completed because connection closed")
                return
            }

            guard let data, data.count == 4 else {
                localPeerLog("\(Self.logPrefix) Invalid frame header length")
                onMessage(.failure(LocalPeerTransportError.invalidFrame))
                receiveLength(onMessage: onMessage)
                return
            }

            let size = data.withUnsafeBytes { rawBuffer -> UInt32 in
                rawBuffer.load(as: UInt32.self).bigEndian
            }
            localPeerLog("\(Self.logPrefix) Received frame header payloadBytes=\(size)")

            receivePayload(length: Int(size), onMessage: onMessage)
        }
    }

    /// Receives a frame payload of exact length.
    ///
    /// - Parameters:
    ///   - length: Expected payload length.
    ///   - onMessage: Called for each decoded message.
    func receivePayload(
        length: Int,
        onMessage: @escaping @Sendable (Result<LocalPeerSyncMessage, Error>) -> Void
    ) {
        connection.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] data, _, isComplete, error in
            guard let self else {
                return
            }

            if let error {
                localPeerLog("\(Self.logPrefix) Receive payload failed: \(error.localizedDescription)")
                onMessage(.failure(error))
                return
            }

            if isComplete {
                localPeerLog("\(Self.logPrefix) Receive payload completed because connection closed")
                return
            }

            guard let data, data.count == length else {
                localPeerLog("\(Self.logPrefix) Invalid payload frame size expected=\(length) actual=\(data?.count ?? 0)")
                onMessage(.failure(LocalPeerTransportError.invalidFrame))
                receiveLength(onMessage: onMessage)
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let message = try decoder.decode(LocalPeerSyncMessage.self, from: data)
                localPeerLog("\(Self.logPrefix) Decoded incoming message type=\(message.type) payloadBytes=\(data.count)")
                onMessage(.success(message))
            } catch {
                localPeerLog("\(Self.logPrefix) Failed to decode payload: \(error.localizedDescription)")
                onMessage(.failure(error))
            }

            receiveLength(onMessage: onMessage)
        }
    }
}

/// Provides Bonjour advertising and browsing for local peer sync.
@MainActor
final class LocalPeerBonjourTransport {
    /// The active listener used for incoming connections.
    private var listener: NWListener?

    /// The active browser used for peer discovery.
    private var browser: NWBrowser?

    /// The queue used by listener and browser.
    private let queue = DispatchQueue(label: "LocalPeerSync.Transport")

    /// The static log prefix used by transport messages.
    private static let logPrefix = "[LOCAL SYNC][Transport]"

    /// Starts hosting a Bonjour service and listens for incoming connections.
    ///
    /// - Parameters:
    ///   - serviceName: The announced Bonjour name.
    ///   - onConnection: Called for each incoming connection.
    /// - Throws: `LocalPeerTransportError` when listener setup fails.
    func startListening(
        serviceName: String,
        onConnection: @escaping @Sendable (LocalPeerConnection) -> Void
    ) throws(LocalPeerTransportError) {
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        let logPrefix = Self.logPrefix
        localPeerLog("\(Self.logPrefix) Starting listener with serviceName='\(serviceName)' type='\(LocalPeerSyncConfiguration.bonjourServiceType)'")

        let listener: NWListener
        do {
            listener = try NWListener(using: parameters)
        } catch {
            localPeerLog("\(Self.logPrefix) Listener creation failed: \(error.localizedDescription)")
            throw .listenerStartFailed
        }

        listener.service = NWListener.Service(
            name: serviceName,
            type: LocalPeerSyncConfiguration.bonjourServiceType
        )

        listener.newConnectionHandler = { connection in
            localPeerLog("\(logPrefix) Listener accepted new incoming NWConnection")
            let wrappedConnection = LocalPeerConnection(connection: connection)
            onConnection(wrappedConnection)
        }
        listener.stateUpdateHandler = { state in
            localPeerLog("\(logPrefix) Listener state changed to \(state)")
        }

        listener.start(queue: queue)
        self.listener = listener
        localPeerLog("\(Self.logPrefix) Listener started")
    }

    /// Starts browsing for peers that advertise the sync service.
    ///
    /// - Parameter onEndpoint: Called for each discovered endpoint.
    /// - Throws: `LocalPeerTransportError` when browser setup fails.
    func startBrowsing(
        onEndpoint: @escaping @Sendable (NWEndpoint) -> Void
    ) throws(LocalPeerTransportError) {
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        let logPrefix = Self.logPrefix
        browser?.cancel()
        browser = nil
        localPeerLog("\(Self.logPrefix) Starting browser for type='\(LocalPeerSyncConfiguration.bonjourServiceType)'")

        let descriptor = NWBrowser.Descriptor.bonjour(
            type: LocalPeerSyncConfiguration.bonjourServiceType,
            domain: nil
        )

        let browser = NWBrowser(for: descriptor, using: parameters)
        browser.stateUpdateHandler = { state in
            localPeerLog("\(logPrefix) Browser state changed to \(state)")
        }
        browser.browseResultsChangedHandler = { results, _ in
            for result in results {
                onEndpoint(result.endpoint)
            }
        }

        browser.start(queue: queue)
        self.browser = browser
        localPeerLog("\(Self.logPrefix) Browser started")
    }

    /// Stops only the active browser while keeping the listener alive.
    func stopBrowsing() {
        browser?.cancel()
        browser = nil
        localPeerLog("\(Self.logPrefix) Browser stopped")
    }

    /// Stops listener and browser.
    func stop() {
        localPeerLog("\(Self.logPrefix) Stopping listener and browser")
        listener?.cancel()
        browser?.cancel()
        listener = nil
        browser = nil
        localPeerLog("\(Self.logPrefix) Listener and browser stopped")
    }

    /// Creates an outgoing connection for a discovered endpoint.
    ///
    /// - Parameter endpoint: The selected endpoint.
    /// - Returns: A wrapped connection object.
    func connect(to endpoint: NWEndpoint) -> LocalPeerConnection {
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        localPeerLog("\(Self.logPrefix) Creating outbound connection to endpoint=\(endpoint)")
        let connection = NWConnection(to: endpoint, using: parameters)
        return LocalPeerConnection(connection: connection)
    }
}
