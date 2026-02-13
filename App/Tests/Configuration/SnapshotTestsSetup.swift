//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SnapshotKit
import XCTest

class SnapshotTestsSetup: NSObject {
    enum Constants {
        static let subpixelThresholdDefaultValue: UInt8 = 5
        static let precisionDefaultValue: Float = 0.999
    }

    /// This code is setup exactly once before the test target runs, since this class is configured as "Principal class" in our target's Info.plist.
    override init() {
        guard SnapshotTestsSetup.isValidTestDevice() else {
            assertionFailure("Test Device is not an iPhone 14 Pro")
            return
        }

        // configure diff tool to get assertion error messages that can be pasted into the terminal
        SnapshotKit.diffTool = "open"
    }

    private static func isValidTestDevice() -> Bool {
        ProcessInfo.processInfo.environment["RUN_DESTINATION_DEVICE_NAME"] == "iPhone 14 Pro"
    }
}
