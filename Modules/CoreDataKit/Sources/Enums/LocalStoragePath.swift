//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

/// An enumeration representing different local storage paths.
public enum LocalStoragePath: Sendable {
    /// Represents the library directory with an optional appending path.
    case libraryDirectory(appending: String? = nil)

    /// Represents the application support directory with an optional appending path.
    case applicationSupportDirectory(appending: String? = nil)

    /// The URL corresponding to the specified local storage path.
    var url: URL? {
        switch self {
        case let .libraryDirectory(appending):
            FileManager.default.urls(
                for: .libraryDirectory,
                in: .userDomainMask
            )
            .first?
            .appendingPathComponent(appending ?? "")
        case let .applicationSupportDirectory(appending):
            FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )
            .first?
            .appendingPathComponent(appending ?? "")
        }
    }
}
