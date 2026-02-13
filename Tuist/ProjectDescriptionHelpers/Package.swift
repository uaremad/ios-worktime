//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import ProjectDescription

// Extension for Package to define different dependencies
/// used in the project.
public extension Package {
    static var snapshotKit: Self {
        .package(url: "git@github.com:lunij/SnapshotKit", .upToNextMajor(from: "0.1.0"))
    }
}
