//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SnapshotKit
import SwiftUI
import XCTest

/// The purpose of this method is to provide the Snapshot tests as an example
class ExampleSnapshotTests: XCTestCase {
    // If true, all snapshots will be new recorded, for testing it should be false.
    let record: Bool = false

    /// The purpose of this method is to run a snapshot test as example
    func testContentView() {
        let view = Text("Small Snapshot Test")

        assertLocalizedSnapshots(
            matching: view,
            as: .imageWithAcceptableInaccuracy(layout: .fixed(width: 420, height: 780)),
            record: record
        )
    }
}

extension Bundle {
    var iconFileName: String? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconFileName = iconFiles.last
        else { return nil }
        return iconFileName
    }
}
