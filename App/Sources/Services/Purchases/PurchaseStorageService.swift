//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

#if os(iOS)
/// Stores purchase-related local state in a dedicated UserDefaults suite.
final class PurchaseStorageService {
    /// Shared purchase storage instance.
    static let shared = PurchaseStorageService()

    /// Key used for manual measurement counting in the purchase context.
    private enum StorageKey {
        static let manualMeasurementCount = "ManualMeasurementCount"
    }

    /// The suite name used to isolate purchase-specific data.
    private static let suiteName = "com.jandamerau.blutdruck.purchases"

    /// Backing UserDefaults store for purchase-specific persistence.
    private let storage: UserDefaults

    /// Creates the purchase storage and migrates existing manual counter state.
    private init() {
        storage = UserDefaults(suiteName: Self.suiteName) ?? .standard
        storage.register(defaults: [StorageKey.manualMeasurementCount: 0])
        migrateLegacyManualMeasurementCountIfNeeded()
    }

    /// Stores how many manual measurements were created on this installation.
    var manualMeasurementCount: Int {
        get { storage.integer(forKey: StorageKey.manualMeasurementCount) }
        set { storage.set(max(0, newValue), forKey: StorageKey.manualMeasurementCount) }
    }

    /// Increments the manual measurement counter by a positive amount.
    ///
    /// - Parameter value: The amount to add.
    func incrementManualMeasurementCount(by value: Int = 1) {
        guard value > 0 else { return }
        manualMeasurementCount += value
    }

    /// Clears all purchase-specific persisted values in the dedicated suite.
    func reset() {
        storage.removeObject(forKey: StorageKey.manualMeasurementCount)
        storage.register(defaults: [StorageKey.manualMeasurementCount: 0])
    }

    /// Migrates an existing manual counter from standard defaults into the purchase suite.
    private func migrateLegacyManualMeasurementCountIfNeeded() {
        guard storage.object(forKey: StorageKey.manualMeasurementCount) == nil else { return }

        let standardDefaults = UserDefaults.standard
        guard let legacyValue = standardDefaults.object(forKey: StorageKey.manualMeasurementCount) as? NSNumber else {
            return
        }
        manualMeasurementCount = max(0, legacyValue.intValue)
    }
}
#endif
