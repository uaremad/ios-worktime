//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import SwiftUI

/// Coordinates the bootstrap selection flow and the main tabbed UI.
struct Bootstrap: View {
    /// UserDefaults keys used by the bootstrap flow.
    private enum StorageKey {
        /// Indicates whether the first-start onboarding has already been completed.
        ///
        /// - Note: The raw key name is kept for backward compatibility.
        static let firstStartPurchasesWasShown = "firstStartPurchasesWasShown"

        /// Legacy key used by the previous bootstrap privacy flow.
        static let legacyPrivacyPolicyWasShown = "privacyPolicyWasShown"
    }

    /// The currently selected tab in the main UI.
    @State private var selectedTab: TabItem.Tab

    /// Indicates whether the first-start onboarding has already been shown.
    @AppStorage(StorageKey.firstStartPurchasesWasShown) private var firstStartPurchasesWasShown: Bool = false

    #if os(iOS)
    /// Controls first-start presentation of the onboarding flow.
    @State private var showsFirstStartOnboarding: Bool = false
    #endif

    /// Ensures first-start evaluation runs only once per app launch.
    @State private var didResolveFirstStart: Bool = false

    /// Creates a new bootstrap coordinator.
    init() {
        _selectedTab = State(initialValue: .start)
    }

    /// The body of the container view.
    var body: some View {
        RootView(tab: selectedTab)
            .transition(.opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .appThemeColors()
            .onAppear {
                resolveFirstStartIfNeeded()
            }
        #if os(iOS)
            .fullScreenCover(isPresented: $showsFirstStartOnboarding) {
                firstStartOnboardingView
            }
        #endif
            .animation(.easeInOut(duration: 0.4), value: selectedTab)
    }

    /// Resolves whether the app should present the first-start onboarding flow.
    private func resolveFirstStartIfNeeded() {
        guard didResolveFirstStart == false else { return }
        didResolveFirstStart = true

        if firstStartPurchasesWasShown == false,
           UserDefaults.standard.bool(forKey: StorageKey.legacyPrivacyPolicyWasShown)
        {
            firstStartPurchasesWasShown = true
        }

        #if os(iOS)
        if firstStartPurchasesWasShown == false {
            showsFirstStartOnboarding = true
        }
        #endif
    }

    #if os(iOS)
    /// The onboarding flow shown once on first app start.
    private var firstStartOnboardingView: some View {
        OnboardingView {
            completeFirstStartOnboardingFlow()
        }
        .interactiveDismissDisabled(true)
    }

    /// Completes the first-start onboarding flow and stores completion state.
    private func completeFirstStartOnboardingFlow() {
        firstStartPurchasesWasShown = true
        showsFirstStartOnboarding = false
    }
    #endif
}
