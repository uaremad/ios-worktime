//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

/// Displays available purchase options and restore action.
@MainActor
struct MoreMenuPurchasesView: View {
    /// Controls whether the navigation title should be displayed.
    private let showsNavigationTitle: Bool

    /// The managed object context used for entitlement refreshes.
    @Environment(\.managedObjectContext) private var viewContext

    #if os(iOS)
    /// Holds all purchase state and actions for this screen.
    @State private var viewModel = MoreMenuPurchasesViewModel()

    /// The horizontal size class used to adapt paywall grid columns.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    /// Creates a purchases screen with optional navigation title.
    ///
    /// - Parameter showsNavigationTitle: Controls visibility of the navigation title.
    init(showsNavigationTitle: Bool = true) {
        self.showsNavigationTitle = showsNavigationTitle
    }

    /// The body of the purchases view.
    var body: some View {
        #if os(iOS)
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: .spacingM) {
                    LazyVGrid(
                        columns: viewModel.purchaseGridColumns(
                            for: proxy.size.width,
                            horizontalSizeClass: horizontalSizeClass
                        ),
                        spacing: .spacingM
                    ) {
                        ForEach(viewModel.cardConfigurations, id: \.productID.rawValue) { config in
                            purchaseCard(config: config)
                        }
                    }

                    Text(L10n.settingsPurchasesFooter)
                        .textStyle(.body3)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    purchaseActionCard(
                        title: L10n.settingsMoreRestorePurchases,
                        symbolName: "arrow.clockwise.circle"
                    ) {
                        Task {
                            await viewModel.restorePurchases(context: viewContext)
                        }
                    }

                    purchaseActionCard(
                        title: L10n.settingsPurchasesManage,
                        symbolName: "gear"
                    ) {
                        Task {
                            await viewModel.openManageSubscriptions()
                        }
                    }
                }
                .padding(.spacingM)
            }
        }
        .background(Color.aBackground)
        .if(showsNavigationTitle) { view in
            view.navigationTitle(L10n.settingsMorePurchasesTitle)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.prepare(context: viewContext)
        }
        #else
        List {
            Section {
                Text(L10n.settingsPurchasesIntro)
                    .textStyle(.body1)
                    .foregroundStyle(Color.aPrimary)
                    .multilineTextAlignment(.leading)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .background(Color.aBackground)
        .if(showsNavigationTitle) { view in
            view.navigationTitle(L10n.settingsMorePurchasesTitle)
        }
        #endif
    }

    #if os(iOS)

    /// Creates one purchase card and binds it to StoreKit action handling.
    ///
    /// - Parameter config: The configuration for the purchase card.
    /// - Returns: One styled purchase card.
    private func purchaseCard(config: MoreMenuPurchaseCardConfig) -> some View {
        purchaseCardLabel(
            config: config,
            displayPrice: viewModel.displayPrice(for: config.productID)
        ) {
            Task {
                await viewModel.purchase(productID: config.productID, context: viewContext)
            }
        }
    }

    /// Creates the common card label UI shared by StoreKit-enabled and fallback states.
    ///
    /// - Parameters:
    ///   - config: The purchase card configuration.
    ///   - displayPrice: The optional StoreKit display price.
    ///   - action: The tap handler for the primary purchase button.
    /// - Returns: The rendered card label.
    private func purchaseCardLabel(
        config: MoreMenuPurchaseCardConfig,
        displayPrice: String?,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack(alignment: .center, spacing: .spacingS) {
                VStack(alignment: .leading, spacing: .spacingXS) {
                    HStack(spacing: .spacingS) {
                        Image(systemName: config.symbolName)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.aPrimary)
                            .imageScale(.large)
                            .accessibilityHidden(true)

                        Text(config.fallbackTitle)
                            .textStyle(.body1)
                            .foregroundStyle(Color.aPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(alignment: .top, spacing: .spacingS) {
                        Image(systemName: "checkmark")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.aPrimary)
                            .imageScale(.small)
                            .padding(.top, 2)
                            .accessibilityHidden(true)

                        Text(config.description)
                            .textStyle(.body3)
                            .foregroundStyle(Color.aPrimary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Text(displayPrice ?? "-")
                    .textStyle(.body1)
                    .foregroundStyle(Color.aPrimary)
                    .frame(minWidth: 80, alignment: .trailing)
            }

            if let savingBadge = config.savingBadge {
                Text(savingBadge)
                    .textStyle(.body3)
                    .foregroundStyle(Color.accentColor)
            }

            Button(action: action) {
                Text(config.fallbackTitle)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(arePurchaseButtonsDisabled)
            .accessibilityLabel(config.fallbackTitle)
            .accessibilityAddTraits(.isButton)
        }
        .padding(.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.aListBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    (isHighlightedCard(config) ? Color.accentColor : Color.aPrimary)
                        .opacity(isHighlightedCard(config) ? 0.35 : 0.16),
                    lineWidth: 1
                )
        )
        .overlay(alignment: .topTrailing) {
            if let badge = purchaseBadge(for: config) {
                Text(badge)
                    .textStyle(.body3)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, .spacingXS)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.accentColor)
                    )
                    .padding(.trailing, .spacingM)
                    .offset(y: -10)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    /// Resolves the badge text for one purchase card based on entitlement context.
    ///
    /// - Parameter config: The purchase card configuration.
    /// - Returns: The badge text to render or `nil` when no badge should be shown.
    private func purchaseBadge(for config: MoreMenuPurchaseCardConfig) -> String? {
        config.badge
    }

    /// Indicates whether the card should use the highlighted accent border.
    ///
    /// - Parameter config: The purchase card configuration.
    /// - Returns: `true` when the card should be accent-highlighted.
    private func isHighlightedCard(_ config: MoreMenuPurchaseCardConfig) -> Bool {
        config.isPopular
    }

    /// Indicates whether purchase buttons should be disabled for the current screen state.
    private var arePurchaseButtonsDisabled: Bool {
        viewModel.isProcessingStoreKitRequest
    }

    /// Creates a secondary action card for restore and subscription management.
    ///
    /// - Parameters:
    ///   - title: The localized action title.
    ///   - symbolName: The SF Symbol to visualize the action.
    ///   - action: The tap handler.
    /// - Returns: A full-width tappable card.
    private func purchaseActionCard(title: String, symbolName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: .spacingS) {
                Image(systemName: symbolName)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.aPrimary)
                    .imageScale(.medium)
                    .accessibilityHidden(true)

                Text(title)
                    .textStyle(.body1)
                    .foregroundStyle(Color.aPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.aPrimary)
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }
            .padding(.spacingM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.aListBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.aPrimary.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .disabled(viewModel.isProcessingStoreKitRequest)
    }
    #endif
}

extension View {
    /// Applies a view transform only when the condition is true.
    ///
    /// - Parameters:
    ///   - condition: The condition that controls transform application.
    ///   - transform: The transform closure to apply.
    /// - Returns: Either transformed or original view.
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
