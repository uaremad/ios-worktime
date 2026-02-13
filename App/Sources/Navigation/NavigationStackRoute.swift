//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import SwiftUI

/// Represents all navigable destinations within the app.
///
/// This enum is used with `NavigationStack` and `NavigationLink(value:)`
/// to define type-safe and centralized routing across modules and detailed views.
///
/// ## Important
/// This enum must be Hashable to work with NavigationStack, so it cannot
/// contain Bindings. Bindings are provided by the NavigationStackFlow when creating views.
public enum NavigationStackRoute: Hashable, Identifiable {
    /// A route to a high-level module destination.
    case module(Destination)

    /// Conforms to `Identifiable` to support use in SwiftUI navigation APIs.
    public var id: Self { self }
}
