//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import Observation
import SwiftUI

/// A global router managing navigation across the entire app.
@Observable
public final class NavigationStackFlow: @unchecked Sendable {
    // MARK: - iOS Properties

    /// The navigation path for iOS NavigationStack.
    public var path = NavigationPath()

    /// The currently selected draft identifier for the writing flow.
    public var selectedDraftId: String?

    // MARK: - Initialization

    public init() {}

    // MARK: - Navigation Methods

    /// Navigates to a specific route.
    ///
    /// **BUGFIX (Dec 2025):** Now appends to path on BOTH platforms.
    /// Previously, macOS only updated sidebar without affecting NavigationStack path,
    /// causing navigation to fail when using NavigationStack on macOS.
    ///
    /// The sidebar selection is still updated for visual consistency,
    /// but the actual navigation happens through path.append() on both platforms.
    public func navigate(to route: NavigationStackRoute) {
        // CRITICAL: Always append to path for NavigationStack to detect
        path.append(route)
    }

    /// Navigates to a specific module.
    public func navigateToModule(_ destination: NavigationStackRoute.Destination) {
        let route = NavigationStackRoute.module(destination)
        navigate(to: route)
    }

    /// Navigates to the writing editor with an optional draft identifier.
    ///
    /// - Parameter draftId: The optional draft identifier to preselect.
    public func navigateToWriting(draftId: String? = nil) {
        selectedDraftId = draftId
        popToRoot()
    }

    /// Pops the last route from the navigation path.
    public func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    /// Resets the navigation to the root.
    public func reset() {
        path = NavigationPath()
    }

    /// Pops all routes and returns to the root view.
    ///
    /// This is useful when you want to ensure a "fresh start" navigation
    /// without any stale routes in the path.
    ///
    /// - Note: This is optional. With proper @Bindable usage, path cleanup
    ///         happens automatically. Use only if you want extra safety.
    public func popToRoot() {
        path = NavigationPath()
    }
}
