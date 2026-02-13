//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

extension LocalPeerSyncCoordinator {
    /// Runs one startup cleanup pass for trusted peers.
    ///
    /// This keeps at most one trust record per device name to avoid
    /// stale peer ids from older pairings.
    func runStartupTrustMaintenance() async {
        do {
            let result = try await deduplicateTrustedPeersByDeviceName()
            if result.removedPeerIds.isEmpty == false {
                localPeerLog(
                    "\(Self.logPrefix) Startup trust maintenance kept=\(result.keptCount) removed=\(result.removedPeerIds.count)"
                )
            }
        } catch {
            localPeerLog("\(Self.logPrefix) Startup trust maintenance failed: \(error.localizedDescription)")
        }
    }

    /// Removes duplicate trusted peers that share the same device name.
    ///
    /// - Returns: The number of kept records and removed peer identifiers.
    /// - Throws: `LocalPeerSyncStoreError` when persistence fails.
    private func deduplicateTrustedPeersByDeviceName() async throws(LocalPeerSyncStoreError) -> (
        keptCount: Int,
        removedPeerIds: [String]
    ) {
        let trustedPeers = try await trustStore.all()
        guard trustedPeers.count > 1 else {
            return (trustedPeers.count, [])
        }

        let groupedPeers = Dictionary(grouping: trustedPeers) { record in
            record.deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var removedPeerIds: [String] = []

        for peers in groupedPeers.values where peers.count > 1 {
            let sortedPeers = peers.sorted(by: Self.isPreferredTrustRecord)
            let peersToRemove = sortedPeers.dropFirst()
            for stalePeer in peersToRemove {
                try await trustStore.remove(peerId: stalePeer.peerId)
                try await checkpointStore.removeAll(peerId: stalePeer.peerId)
                connections.removeValue(forKey: stalePeer.peerId)
                approvedIncomingSyncPeerIds.remove(stalePeer.peerId)
                removedPeerIds.append(stalePeer.peerId)
            }
        }

        if removedPeerIds.isEmpty {
            return (trustedPeers.count, [])
        }

        let remainingPeers = try await trustStore.all()
        return (remainingPeers.count, removedPeerIds.sorted())
    }

    /// Returns whether one trust record should be preferred over another.
    ///
    /// - Parameters:
    ///   - lhs: The left trust record.
    ///   - rhs: The right trust record.
    /// - Returns: `true` when `lhs` should be kept over `rhs`.
    private static func isPreferredTrustRecord(
        _ lhs: LocalPeerTrustRecord,
        _ rhs: LocalPeerTrustRecord
    ) -> Bool {
        let lhsActivity = lhs.lastSuccessfulSyncAt ?? lhs.pairedAt
        let rhsActivity = rhs.lastSuccessfulSyncAt ?? rhs.pairedAt
        if lhsActivity != rhsActivity {
            return lhsActivity > rhsActivity
        }
        if lhs.pairedAt != rhs.pairedAt {
            return lhs.pairedAt > rhs.pairedAt
        }
        return lhs.peerId > rhs.peerId
    }
}
