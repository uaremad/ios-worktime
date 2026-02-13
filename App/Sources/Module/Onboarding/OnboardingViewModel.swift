//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import Observation

#if os(iOS)
/// Stores state for the first-start onboarding pager.
@MainActor
@Observable
final class OnboardingViewModel {
    /// Defines one onboarding page.
    enum Page: Int, CaseIterable, Identifiable {
        /// The terminology setup screen.
        case terminology

        /// The activity setup screen.
        case activities

        /// The cost centre setup screen.
        case costCentres

        /// The purchases setup screen.
        case purchases

        /// The stable identifier used for `ForEach` and selection.
        var id: Int { rawValue }
    }

    /// All pages rendered by the onboarding TabView.
    let pages: [Page] = Page.allCases

    /// The currently selected page.
    var selectedPage: Page = .terminology

    /// Indicates whether the current page is the last onboarding step.
    var isOnLastPage: Bool {
        guard let currentIndex = pages.firstIndex(of: selectedPage) else {
            return true
        }
        return currentIndex == pages.index(before: pages.endIndex)
    }

    /// Moves selection to the next page when possible.
    ///
    /// - Returns: `true` when the page changed, otherwise `false`.
    func goToNextPageIfPossible() -> Bool {
        guard let currentIndex = pages.firstIndex(of: selectedPage) else {
            return false
        }
        let nextIndex = currentIndex + 1
        guard pages.indices.contains(nextIndex) else {
            return false
        }
        selectedPage = pages[nextIndex]
        return true
    }
}
#endif
