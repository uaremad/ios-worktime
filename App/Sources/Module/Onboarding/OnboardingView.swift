//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

#if os(iOS)
/// Presents first-start onboarding with swipeable setup pages.
@MainActor
struct OnboardingView: View {
    /// Closure executed when onboarding should be completed.
    private let onComplete: () -> Void

    /// Holds paging state for onboarding.
    @State private var viewModel = OnboardingViewModel()

    /// Creates one onboarding screen.
    ///
    /// - Parameter onComplete: Closure called to finish onboarding.
    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    /// The onboarding pager body.
    var body: some View {
        NavigationStack {
            TabView(selection: selectedPageBinding) {
                ForEach(viewModel.pages) { page in
                    pageContainer(for: page)
                        .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .safeAreaInset(edge: .bottom) {
                pageIndicator
                    .padding(.bottom, .spacingS)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        handleSkipAction()
                    } label: {
                        Text(L10n.purchaseSkip)
                            .textStyle(.body1)
                    }
                    .buttonStyle(TextButtonStyle())
                    .accessibilityLabel(L10n.purchaseSkip)
                    .accessibilityHint(L10n.purchaseSkip)
                }
            }
        }
    }

    /// Displays the current onboarding page position as dots.
    private var pageIndicator: some View {
        HStack(spacing: .spacingXS) {
            ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, _ in
                Circle()
                    .fill(index == currentPageIndex ? Color.accentColor : Color.aPrimary.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, .spacingS)
        .padding(.vertical, .spacingXS)
        .background(
            Capsule(style: .continuous)
                .fill(Color.aListBackground)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.aPrimary.opacity(0.12), lineWidth: 1)
        )
    }

    /// Resolves the zero-based index of the currently selected page.
    private var currentPageIndex: Int {
        viewModel.pages.firstIndex(of: viewModel.selectedPage) ?? 0
    }

    /// Wraps one onboarding page and optionally renders onboarding helper text.
    ///
    /// - Parameter page: The onboarding page that should be wrapped.
    /// - Returns: The wrapped onboarding page content.
    @ViewBuilder
    private func pageContainer(for page: OnboardingViewModel.Page) -> some View {
        VStack(spacing: .spacingS) {
            if let onboardingHintText = onboardingHintText(for: page) {
                onboardingHintBanner(text: onboardingHintText)
                    .padding(.horizontal, .spacingS)
            }
            pageView(for: page)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.top, .spacingS)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.aBackground)
    }

    /// Resolves optional onboarding helper text for one page.
    ///
    /// - Parameter page: The onboarding page to resolve.
    /// - Returns: An optional helper text for this page.
    private func onboardingHintText(for page: OnboardingViewModel.Page) -> String? {
        switch page {
        case .terminology:
            nil
        case .activities:
            nil
        case .costCentres:
            L10n.managementOnboardingCostCentreHint
        case .purchases:
            nil
        }
    }

    /// Renders a highlighted onboarding helper text banner.
    ///
    /// - Parameter text: The helper text to display.
    /// - Returns: The helper banner view.
    private func onboardingHintBanner(text: String) -> some View {
        Text(text)
            .textStyle(.body3)
            .foregroundStyle(Color.aPrimary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.spacingS)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.aListBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.aPrimary.opacity(0.15), lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
    }

    /// Advances to the next onboarding page or completes the flow on the last page.
    private func handleSkipAction() {
        guard viewModel.isOnLastPage else {
            withAnimation {
                _ = viewModel.goToNextPageIfPossible()
            }
            return
        }
        onComplete()
    }

    /// Returns the page content for one onboarding step.
    ///
    /// - Parameter page: The page that should be rendered.
    /// - Returns: The corresponding page view.
    @ViewBuilder
    private func pageView(for page: OnboardingViewModel.Page) -> some View {
        switch page {
        case .terminology:
            TerminologySettingsView(showsNavigationToolbar: false)
        case .activities:
            ActivitySettingsListView()
        case .costCentres:
            CostCentreListView()
        case .purchases:
            MoreMenuPurchasesView(showsNavigationTitle: false)
        }
    }

    /// Provides a binding to the currently selected onboarding page.
    private var selectedPageBinding: Binding<OnboardingViewModel.Page> {
        Binding(
            get: { viewModel.selectedPage },
            set: { newValue in
                viewModel.selectedPage = newValue
            }
        )
    }
}
#endif
