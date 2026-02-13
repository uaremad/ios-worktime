//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

/// An enumeration representing the mode of synchronization with iCloud.
public enum CloudSyncMode: Equatable, @unchecked Sendable {
    /// Indicates synchronization with a specific iCloud container.
    case container(containerID: String, scope: Scope)

    /// Indicates no synchronization with iCloud.
    case none

    /// An enumeration representing the scope of iCloud synchronization.
    public enum Scope: Int, @unchecked Sendable {
        /// Indicates synchronization with the public iCloud database.
        case `public` = 1

        /// Indicates synchronization with the private iCloud database.
        case `private` = 2

        /// Indicates synchronization with a shared iCloud database.
        case shared = 3
    }
}
