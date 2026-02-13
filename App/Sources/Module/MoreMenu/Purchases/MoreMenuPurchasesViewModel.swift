//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI
#if canImport(StoreKit)
import StoreKit
#endif
#if canImport(UIKit)
import UIKit
#endif

#if os(iOS)
/// Configuration for one purchase card on the paywall.
struct MoreMenuPurchaseCardConfig: Sendable {
    /// The product identifier tied to this card.
    let productID: PurchaseProductID

    /// The localized fallback title when StoreKit metadata is unavailable.
    let fallbackTitle: String

    /// The localized description shown as primary benefit text.
    let description: String

    /// The SF Symbol used as card icon.
    let symbolName: String

    /// The optional badge text shown near the card border.
    let badge: String?

    /// The optional savings text shown below the title row.
    let savingBadge: String?

    /// Indicates whether this card should be visually highlighted.
    let isPopular: Bool
}

/// Manages state and actions for the purchases screen.
@MainActor
@Observable
final class MoreMenuPurchasesViewModel {
    /// The ordered paywall card definitions bound to current product IDs.
    let cardConfigurations: [MoreMenuPurchaseCardConfig] = [
        MoreMenuPurchaseCardConfig(
            productID: .monthly,
            fallbackTitle: L10n.purchaseMonthlyName,
            description: L10n.purchaseMonthlyDescription,
            symbolName: "calendar",
            badge: nil,
            savingBadge: L10n.settingsPurchasesMonthlyCancelable,
            isPopular: false
        ),
        MoreMenuPurchaseCardConfig(
            productID: .yearly,
            fallbackTitle: L10n.purchaseAnnualName,
            description: L10n.purchaseAnnualDescription,
            symbolName: "calendar.badge.clock",
            badge: L10n.settingsPurchasesPopular,
            savingBadge: L10n.settingsPurchasesSaveTwoMonths,
            isPopular: true
        ),
        MoreMenuPurchaseCardConfig(
            productID: .lifetime,
            fallbackTitle: L10n.purchaseLifetimeName,
            description: L10n.purchaseLifetimeDescription,
            symbolName: "seal",
            badge: nil,
            savingBadge: nil,
            isPopular: false
        )
    ]

    /// The shared entitlement state used for purchase and restore operations.
    private let entitlementStore: EntitlementStore

    #if canImport(StoreKit)
    /// Cached products loaded from StoreKit keyed by product identifier.
    private var productsByIdentifier: [String: Product] = [:]
    #endif

    /// Indicates whether a StoreKit request is currently being processed.
    var isProcessingStoreKitRequest: Bool {
        entitlementStore.isProcessingStoreKitRequest
    }

    /// Creates a purchases view model instance using the shared entitlement store.
    init() {
        entitlementStore = .shared
    }

    /// Creates a purchases view model instance.
    ///
    /// - Parameter entitlementStore: The entitlement store used by the paywall.
    init(entitlementStore: EntitlementStore) {
        self.entitlementStore = entitlementStore
    }

    /// Refreshes entitlements and loads available StoreKit products.
    ///
    /// - Parameter context: The managed object context used for entitlement refreshes.
    func prepare(context: NSManagedObjectContext) async {
        await entitlementStore.refresh(context: context, includingStoreKitChecks: true)
        await loadProducts()
    }

    /// Creates grid column definitions for purchase cards.
    ///
    /// - Parameters:
    ///   - width: The current available container width.
    ///   - horizontalSizeClass: The current horizontal size class from the environment.
    /// - Returns: One or two flexible columns based on size class and width.
    func purchaseGridColumns(
        for width: CGFloat,
        horizontalSizeClass: UserInterfaceSizeClass?
    ) -> [GridItem] {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let isWideLayout = width >= 700
        let usesTwoColumns = isPad || horizontalSizeClass == .regular || isWideLayout
        let columnCount = usesTwoColumns ? 2 : 1
        return Array(
            repeating: GridItem(.flexible(), spacing: .spacingM, alignment: .top),
            count: columnCount
        )
    }

    /// Returns the loaded display price for a paywall product.
    ///
    /// - Parameter productID: The product identifier for the requested card.
    /// - Returns: The localized display price when available.
    func displayPrice(for productID: PurchaseProductID) -> String? {
        #if canImport(StoreKit)
        productsByIdentifier[productID.rawValue]?.displayPrice
        #else
        nil
        #endif
    }

    /// Starts the purchase flow for one paywall product.
    ///
    /// - Parameters:
    ///   - productID: The selected product identifier.
    ///   - context: The managed object context used for post-purchase refresh.
    func purchase(productID: PurchaseProductID, context: NSManagedObjectContext) async {
        #if canImport(StoreKit)
        if let product = productsByIdentifier[productID.rawValue] {
            _ = await entitlementStore.purchase(product: product, context: context)
        } else {
            await loadProducts()
        }
        #endif
    }

    /// Restores StoreKit purchases and refreshes entitlement state.
    ///
    /// - Parameter context: The managed object context used for post-restore refresh.
    func restorePurchases(context: NSManagedObjectContext) async {
        await entitlementStore.restorePurchases(context: context)
    }

    /// Opens the App Store subscriptions management screen when available.
    func openManageSubscriptions() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        do {
            try await AppStore.showManageSubscriptions(in: windowScene)
        } catch {
            // Keep presentation failures silent and keep the screen responsive.
        }
    }

    /// Loads products strictly from configured paywall product identifiers.
    private func loadProducts() async {
        #if canImport(StoreKit)
        do {
            let products = try await Product.products(for: PurchaseProductID.allPaywallIdentifiers)
            productsByIdentifier = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        } catch {
            productsByIdentifier = [:]
        }
        #endif
    }
}
#endif
