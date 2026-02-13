# Local Peer Sync (iOS <-> macOS)

## Scope

This module provides local network synchronization without cloud or backend services.

- Discovery: Bonjour (`_appsync._tcp`)
- Transport: `NWConnection` with framed JSON messages
- Pairing: QR bootstrap payload + handshake (`pairHello`, `pairConfirm`, `pairDone`)
- Trust: Keychain-persisted peer records (peer id + pinned fingerprint)
- Delta Sync: Core Data Persistent History (`syncRequest`, `syncResponse`, `ack`)

## Pairing Payload

`PairingQRCodePayload` contains:

- `pairingSessionId`
- `bonjourServiceType`
- `expectedPeerDeviceId` (optional)
- `pairingSecret` (short-lived)
- `protocolVersion`
- `expiresAt`

Payload serialization for QR uses Base64-encoded JSON.

## Protocol Messages

Envelope: `LocalPeerSyncMessage`

- `pairHello`: Scanner starts pairing with `pairingSessionId` and `pairingSecret`
- `pairConfirm`: Provider confirms and returns provider identity/fingerprint
- `pairDone`: Scanner persists trust and confirms completion
- `syncRequest`: Peer requests delta since local checkpoint token
- `syncResponse`: Peer returns delta + `newTokenData`
- `ack`: Receiver confirms `newTokenData` checkpoint
- `error`: Protocol-level failure

## Delta Format

`LocalPeerSyncDelta`

- `upserts[]`: entity name, identity selector, field snapshot, `modifiedAt`, version
- `deletes[]`: entity name, identity selector, `deletedAt`
- `newTokenData`: archived `NSPersistentHistoryToken`

Conflict strategy is deterministic `last write wins` using `modifiedAt`.

## Persistence

- Trust records: Keychain (`LocalPeerTrustStore`)
- Local identity and pseudo fingerprint: Keychain (`LocalPeerIdentityStore`)
- History checkpoints: UserDefaults (`LocalPeerHistoryCheckpointStore`)

## Core Data Requirements

Persistent store options must be enabled:

- `NSPersistentHistoryTrackingKey = true`
- `NSPersistentStoreRemoteChangeNotificationPostOptionKey = true`

## Runtime Integration

- iOS bootstrap: `BloodpressureApp.startLocalPeerSyncIfNeeded()`
- macOS bootstrap: `MacDelegate.applicationDidFinishLaunching`

Both configure and start `LocalPeerSyncCoordinator` with the active Core Data container.

## Troubleshooting

- Pairing rejected: verify QR payload not expired and protocol version matches.
- No peers discovered: verify same local network and Bonjour service type `_appsync._tcp`.
- Sync does not advance: inspect checkpoint records and verify `ack` handling.
- Unexpected deletes/upserts: verify entity identity mapping (`timestamp` / `dtmMeasured`).
