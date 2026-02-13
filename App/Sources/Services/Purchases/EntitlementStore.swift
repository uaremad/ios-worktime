//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation
#if canImport(StoreKit)
import StoreKit
#endif

#if os(iOS)

/// Defines the effective app access level used for premium gating.
enum AccessLevel: String, Sendable {
    /// Grants free access while under the manual measurement threshold.
    case free

    /// Grants premium access through an active auto-renewable subscription.
    case subscription

    /// Grants premium access through a lifetime entitlement.
    case lifetime

    /// Denies premium actions until a valid entitlement is acquired.
    case locked
}

/// Stores monetization configuration used by entitlement resolution.
enum EntitlementConfiguration {
    /// The hard free-tier limit for manual measurements.
    static let freeManualMeasurementLimit = 20
}

/// Central source of truth for purchase entitlements and access gating.
@MainActor
@Observable
final class EntitlementStore {
    /// The shared singleton instance used across iOS entry points.
    static let shared = EntitlementStore()

    /// The most recently resolved app access level.
    private(set) var accessLevel: AccessLevel = .free

    /// The current amount of manual measurements in local storage.
    private(set) var manualMeasurementCount: Int = 0

    /// Indicates whether a refresh operation is running.
    private(set) var isRefreshing: Bool = false

    /// Indicates whether a StoreKit purchase or restore operation is running.
    private(set) var isProcessingStoreKitRequest: Bool = false

    /// Creates one entitlement store with default values.
    private init() {}

    /// Returns whether manual measurement creation is currently allowed.
    var canCreateManualMeasurements: Bool {
        switch accessLevel {
        case .free, .subscription, .lifetime:
            true
        case .locked:
            false
        }
    }

    /// Refreshes manual counters and optionally StoreKit entitlements.
    ///
    /// - Parameters:
    ///   - context: The managed object context used for local counting.
    ///   - includingStoreKitChecks: Indicates whether StoreKit queries should run.
    func refresh(
        context: NSManagedObjectContext,
        includingStoreKitChecks: Bool = false
    ) async {
        guard isRefreshing == false else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let manualCount = await ManualMeasurementCounter.count(in: context)
        let entitlementSnapshot = if includingStoreKitChecks || shouldRunBackgroundStoreKitChecks {
            await loadStoreKitEntitlements()
        } else {
            StoreKitEntitlementSnapshot(
                hasLifetimePurchase: false,
                hasActiveSubscription: false
            )
        }
        manualMeasurementCount = manualCount
        accessLevel = resolveAccessLevel(
            manualMeasurementCount: manualCount,
            hasLifetimePurchase: entitlementSnapshot.hasLifetimePurchase,
            hasActiveSubscription: entitlementSnapshot.hasActiveSubscription
        )
    }

    #if canImport(StoreKit)
    /// Purchases one StoreKit product and refreshes entitlements afterward.
    ///
    /// - Parameters:
    ///   - product: The StoreKit product to purchase.
    ///   - context: The managed object context used for post-purchase refresh.
    /// - Returns: `true` when the purchase produced a verified entitlement.
    func purchase(product: Product, context: NSManagedObjectContext) async -> Bool {
        guard isProcessingStoreKitRequest == false else { return false }
        isProcessingStoreKitRequest = true
        defer { isProcessingStoreKitRequest = false }

        do {
            let purchaseResult = try await product.purchase()
            switch purchaseResult {
            case let .success(verification):
                guard case let .verified(transaction) = verification else {
                    await refresh(context: context, includingStoreKitChecks: true)
                    return false
                }
                await transaction.finish()
                await refresh(context: context, includingStoreKitChecks: true)
                return true
            case .pending, .userCancelled:
                await refresh(context: context, includingStoreKitChecks: true)
                return false
            @unknown default:
                await refresh(context: context, includingStoreKitChecks: true)
                return false
            }
        } catch {
            await refresh(context: context, includingStoreKitChecks: true)
            return false
        }
    }

    /// Restores purchases via App Store sync and refreshes entitlements.
    ///
    /// - Parameter context: The managed object context used for post-restore refresh.
    func restorePurchases(context: NSManagedObjectContext) async {
        guard isProcessingStoreKitRequest == false else { return }
        isProcessingStoreKitRequest = true
        defer { isProcessingStoreKitRequest = false }

        do {
            try await AppStore.sync()
        } catch {
            // Keep errors silent and still trigger one fresh entitlement read.
        }
        await refresh(context: context, includingStoreKitChecks: true)
    }
    #endif
}

private extension EntitlementStore {
    /// Indicates whether automatic StoreKit checks should run outside purchase flows.
    var shouldRunBackgroundStoreKitChecks: Bool {
        #if targetEnvironment(simulator)
        false
        #else
        true
        #endif
    }

    /// Snapshot model for all StoreKit-derived entitlement signals.
    struct StoreKitEntitlementSnapshot: Sendable {
        /// Indicates that the lifetime non-consumable is currently owned.
        let hasLifetimePurchase: Bool

        /// Indicates that an active subscription entitlement exists.
        let hasActiveSubscription: Bool
    }

    /// Resolves the final access level using the configured priority rules.
    ///
    /// - Parameters:
    ///   - manualMeasurementCount: The current manual measurement count.
    ///   - hasLifetimePurchase: Indicates lifetime product ownership.
    ///   - hasActiveSubscription: Indicates active monthly/yearly subscription.
    /// - Returns: The resolved access level.
    func resolveAccessLevel(
        manualMeasurementCount: Int,
        hasLifetimePurchase: Bool,
        hasActiveSubscription: Bool
    ) -> AccessLevel {
        if hasLifetimePurchase {
            return .lifetime
        }
        if hasActiveSubscription {
            return .subscription
        }
        if manualMeasurementCount < EntitlementConfiguration.freeManualMeasurementLimit {
            return .free
        }
        return .locked
    }

    /// Reads all StoreKit entitlement signals required for access resolution.
    ///
    /// - Returns: A snapshot containing current lifetime and subscription entitlements.
    func loadStoreKitEntitlements() async -> StoreKitEntitlementSnapshot {
        #if canImport(StoreKit)
        var hasLifetimePurchase = false
        var hasActiveSubscription = false

        let now = Date()
        for await verification in Transaction.currentEntitlements {
            guard case let .verified(transaction) = verification else { continue }
            guard transaction.revocationDate == nil else { continue }

            if transaction.productID == PurchaseProductID.lifetime.rawValue {
                hasLifetimePurchase = true
                continue
            }

            if PurchaseProductID.subscriptionIdentifiers.contains(transaction.productID) {
                if let expirationDate = transaction.expirationDate, expirationDate <= now {
                    continue
                }
                hasActiveSubscription = true
            }
        }

        return StoreKitEntitlementSnapshot(
            hasLifetimePurchase: hasLifetimePurchase,
            hasActiveSubscription: hasActiveSubscription
        )
        #else
        StoreKitEntitlementSnapshot(
            hasLifetimePurchase: false,
            hasActiveSubscription: false
        )
        #endif
    }
}

private enum ManualMeasurementCounter {
    /// Reads the manual measurement counter from shared settings storage.
    ///
    /// - Parameter context: The managed object context used for counting.
    /// - Returns: The amount of manual measurements.
    @MainActor
    static func count(in context: NSManagedObjectContext) async -> Int {
        _ = context
        return PurchaseStorageService.shared.manualMeasurementCount
    }
}
#endif
