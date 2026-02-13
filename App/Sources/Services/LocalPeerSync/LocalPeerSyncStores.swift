//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import Security

/// Namespaces trust and checkpoint persistence stores for local sync.
enum LocalPeerSyncStores {}

/// Defines errors produced by local peer trust and checkpoint stores.
enum LocalPeerSyncStoreError: Error {
    /// Indicates an invalid record encoding state.
    case invalidEncoding

    /// Indicates a Keychain operation failure with the raw status code.
    case keychainFailure(OSStatus)
}

/// Persists trusted peers in Keychain.
actor LocalPeerTrustStore {
    /// The Keychain service identifier used to isolate app records.
    private let service: String

    /// The account key storing the encoded trust dictionary.
    private let account: String

    /// Creates a new trust store instance.
    ///
    /// - Parameters:
    ///   - service: The Keychain service identifier.
    ///   - account: The Keychain account key.
    init(
        service: String = "com.jandamerau.worktime.localpeersync",
        account: String = "trusted-peers"
    ) {
        self.service = service
        self.account = account
    }

    /// Saves or updates one trust record.
    ///
    /// - Parameter record: The trust record to persist.
    /// - Throws: `LocalPeerSyncStoreError` if persistence fails.
    func save(_ record: LocalPeerTrustRecord) throws(LocalPeerSyncStoreError) {
        var records = try loadAll()
        records[record.peerId] = record
        try writeAll(records)
    }

    /// Loads one trust record for a peer id.
    ///
    /// - Parameter peerId: The peer identifier.
    /// - Returns: The matching trust record, or `nil`.
    /// - Throws: `LocalPeerSyncStoreError` if reading fails.
    func load(peerId: String) throws(LocalPeerSyncStoreError) -> LocalPeerTrustRecord? {
        try loadAll()[peerId]
    }

    /// Removes one trust record by peer id.
    ///
    /// - Parameter peerId: The peer identifier to remove.
    /// - Throws: `LocalPeerSyncStoreError` if persistence fails.
    func remove(peerId: String) throws(LocalPeerSyncStoreError) {
        var records = try loadAll()
        records.removeValue(forKey: peerId)
        try writeAll(records)
    }

    /// Removes all trusted peer records.
    ///
    /// - Throws: `LocalPeerSyncStoreError` if persistence fails.
    func removeAll() throws(LocalPeerSyncStoreError) {
        try writeAll([:])
    }

    /// Returns all trusted peers.
    ///
    /// - Returns: A sorted array of trusted peers.
    /// - Throws: `LocalPeerSyncStoreError` if reading fails.
    func all() throws(LocalPeerSyncStoreError) -> [LocalPeerTrustRecord] {
        try loadAll().values.sorted(by: { $0.deviceName < $1.deviceName })
    }

    /// Loads all records from Keychain.
    ///
    /// - Returns: A dictionary keyed by peer id.
    /// - Throws: `LocalPeerSyncStoreError` if reading or decoding fails.
    private func loadAll() throws(LocalPeerSyncStoreError) -> [String: LocalPeerTrustRecord] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return [:]
        }
        guard status == errSecSuccess else {
            throw .keychainFailure(status)
        }

        guard let data = result as? Data else {
            throw .invalidEncoding
        }

        do {
            return try JSONDecoder().decode([String: LocalPeerTrustRecord].self, from: data)
        } catch {
            throw .invalidEncoding
        }
    }

    /// Writes all records to Keychain.
    ///
    /// - Parameter records: The dictionary to persist.
    /// - Throws: `LocalPeerSyncStoreError` if writing fails.
    private func writeAll(_ records: [String: LocalPeerTrustRecord]) throws(LocalPeerSyncStoreError) {
        let data: Data
        do {
            data = try JSONEncoder().encode(records)
        } catch {
            throw .invalidEncoding
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus == errSecItemNotFound {
            var insertQuery = query
            insertQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(insertQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw .keychainFailure(addStatus)
            }
            return
        }

        throw .keychainFailure(updateStatus)
    }
}

/// Persists per-peer history checkpoints in user defaults.
actor LocalPeerHistoryCheckpointStore {
    /// The storage key used in user defaults.
    private let storageKey: String

    /// The user defaults instance used for persistence.
    private let defaults: UserDefaults

    /// Creates a checkpoint store.
    ///
    /// - Parameters:
    ///   - storageKey: The defaults key.
    ///   - defaults: The defaults instance.
    init(
        storageKey: String = "LocalPeerSyncHistoryCheckpoints",
        defaults: UserDefaults = .standard
    ) {
        self.storageKey = storageKey
        self.defaults = defaults
    }

    /// Saves a checkpoint for one peer and direction.
    ///
    /// - Parameters:
    ///   - peerId: The peer identifier.
    ///   - direction: The sync direction identifier.
    ///   - tokenData: The archived token.
    /// - Throws: `LocalPeerSyncStoreError` when encoding fails.
    func save(
        peerId: String,
        direction: String,
        tokenData: Data
    ) throws(LocalPeerSyncStoreError) {
        var records = try loadAll()
        let record = LocalPeerHistoryCheckpoint(
            peerId: peerId,
            direction: direction,
            tokenData: tokenData,
            updatedAt: Date()
        )
        records[compositeKey(peerId: peerId, direction: direction)] = record
        try writeAll(records)
    }

    /// Loads a checkpoint for one peer and direction.
    ///
    /// - Parameters:
    ///   - peerId: The peer identifier.
    ///   - direction: The sync direction identifier.
    /// - Returns: The matching checkpoint if available.
    /// - Throws: `LocalPeerSyncStoreError` when decoding fails.
    func load(
        peerId: String,
        direction: String
    ) throws(LocalPeerSyncStoreError) -> LocalPeerHistoryCheckpoint? {
        try loadAll()[compositeKey(peerId: peerId, direction: direction)]
    }

    /// Removes all checkpoints for one peer.
    ///
    /// - Parameter peerId: The peer identifier.
    /// - Throws: `LocalPeerSyncStoreError` when encoding fails.
    func removeAll(peerId: String) throws(LocalPeerSyncStoreError) {
        let prefix = "\(peerId)::"
        var records = try loadAll()
        records = records.filter { key, _ in
            key.hasPrefix(prefix) == false
        }
        try writeAll(records)
    }

    /// Removes all checkpoint records.
    func removeAll() {
        defaults.removeObject(forKey: storageKey)
    }

    /// Loads all checkpoint records.
    ///
    /// - Returns: Dictionary of checkpoints keyed by composite key.
    /// - Throws: `LocalPeerSyncStoreError` when decoding fails.
    private func loadAll() throws(LocalPeerSyncStoreError) -> [String: LocalPeerHistoryCheckpoint] {
        guard let data = defaults.data(forKey: storageKey) else {
            return [:]
        }

        do {
            return try JSONDecoder().decode([String: LocalPeerHistoryCheckpoint].self, from: data)
        } catch {
            throw .invalidEncoding
        }
    }

    /// Writes all checkpoints to user defaults.
    ///
    /// - Parameter records: The records to persist.
    /// - Throws: `LocalPeerSyncStoreError` when encoding fails.
    private func writeAll(_ records: [String: LocalPeerHistoryCheckpoint]) throws(LocalPeerSyncStoreError) {
        do {
            let data = try JSONEncoder().encode(records)
            defaults.set(data, forKey: storageKey)
        } catch {
            throw .invalidEncoding
        }
    }

    /// Builds a composite key for peer and direction.
    ///
    /// - Parameters:
    ///   - peerId: The peer identifier.
    ///   - direction: The sync direction.
    /// - Returns: A deterministic storage key.
    private func compositeKey(peerId: String, direction: String) -> String {
        "\(peerId)::\(direction)"
    }
}

/// Stores aggregated transfer statistics per trusted peer.
actor LocalPeerSyncStatsStore {
    /// The storage key used in user defaults.
    private let storageKey: String

    /// The user defaults instance used for persistence.
    private let defaults: UserDefaults

    /// Creates a stats store instance.
    ///
    /// - Parameters:
    ///   - storageKey: The defaults key.
    ///   - defaults: The defaults instance.
    init(
        storageKey: String = "LocalPeerSyncStats",
        defaults: UserDefaults = .standard
    ) {
        self.storageKey = storageKey
        self.defaults = defaults
    }

    /// Adds one transfer sample to the peer statistics.
    ///
    /// - Parameters:
    ///   - peerId: The trusted peer identifier.
    ///   - bytes: The number of bytes transferred.
    ///   - date: The transfer timestamp.
    /// - Throws: `LocalPeerSyncStoreError` when encoding fails.
    func addTransfer(
        peerId: String,
        bytes: Int64,
        date: Date
    ) throws(LocalPeerSyncStoreError) {
        var stats = try loadAll()
        let existing = stats[peerId] ?? LocalPeerSyncStats(
            peerId: peerId,
            totalSyncedBytes: 0,
            lastTransferAt: nil
        )
        stats[peerId] = LocalPeerSyncStats(
            peerId: peerId,
            totalSyncedBytes: existing.totalSyncedBytes + max(0, bytes),
            lastTransferAt: date
        )
        try writeAll(stats)
    }

    /// Loads the statistics for one peer.
    ///
    /// - Parameter peerId: The trusted peer identifier.
    /// - Returns: The stored statistics or `nil` if absent.
    /// - Throws: `LocalPeerSyncStoreError` when decoding fails.
    func load(peerId: String) throws(LocalPeerSyncStoreError) -> LocalPeerSyncStats? {
        try loadAll()[peerId]
    }

    /// Loads all stored peer statistics.
    ///
    /// - Returns: Statistics keyed by peer identifier.
    /// - Throws: `LocalPeerSyncStoreError` when decoding fails.
    func loadAll() throws(LocalPeerSyncStoreError) -> [String: LocalPeerSyncStats] {
        guard let data = defaults.data(forKey: storageKey) else {
            return [:]
        }
        do {
            return try JSONDecoder().decode([String: LocalPeerSyncStats].self, from: data)
        } catch {
            throw .invalidEncoding
        }
    }

    /// Persists all peer statistics.
    ///
    /// - Parameter stats: Statistics keyed by peer identifier.
    /// - Throws: `LocalPeerSyncStoreError` when encoding fails.
    private func writeAll(_ stats: [String: LocalPeerSyncStats]) throws(LocalPeerSyncStoreError) {
        do {
            let data = try JSONEncoder().encode(stats)
            defaults.set(data, forKey: storageKey)
        } catch {
            throw .invalidEncoding
        }
    }

    /// Removes all persisted transfer statistics.
    func removeAll() {
        defaults.removeObject(forKey: storageKey)
    }
}
