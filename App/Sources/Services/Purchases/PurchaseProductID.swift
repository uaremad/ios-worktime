//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

#if os(iOS)
/// Defines all StoreKit product identifiers used by the iOS paywall.
enum PurchaseProductID: String, CaseIterable, Sendable {
    /// Monthly auto-renewable subscription.
    case monthly = "bloodpressure_ios_monthly"

    /// Yearly auto-renewable subscription.
    case yearly = "bloodpressure_ios_yearly"

    /// One-time lifetime non-consumable purchase.
    case lifetime = "bloodpressure_ios_lifetime"

    /// Returns all paywall product identifiers in one centralized list.
    static var allPaywallIdentifiers: [String] {
        allCases.map(\.rawValue)
    }

    /// Returns all subscription product identifiers.
    static var subscriptionIdentifiers: Set<String> {
        [
            PurchaseProductID.monthly.rawValue,
            PurchaseProductID.yearly.rawValue
        ]
    }
}
#endif
