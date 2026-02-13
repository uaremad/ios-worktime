//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SnapshotKit
import SwiftUI
import XCTest

extension XCTestCase {
    func assertLocalizedSnapshotsOnMultipleDevices<Value: SwiftUI.View>(
        matching value: Value,
        named name: String? = nil,
        record recording: Bool = false,
        timeout: TimeInterval = 5,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let devices: [Snapshotting<Value, UIImage>] = [
            .imageWithAcceptableInaccuracy(layout: .device(config: .iPhoneXr)),
            .imageWithAcceptableInaccuracy(layout: .device(config: .iPhoneSe)),
            .imageWithAcceptableInaccuracy(layout: .device(config: .iPhoneXsMax))
        ]

        for device in devices {
            assertLocalizedSnapshots(
                matching: value,
                as: device,
                named: name,
                record: recording,
                timeout: timeout,
                file: file,
                testName: testName,
                line: line
            )
        }
    }

    func assertLocalizedSnapshots<Value>(
        matching value: Value,
        as snapshotting: Snapshotting<Value, some Any>,
        named name: String? = nil,
        record recording: Bool = false,
        timeout: TimeInterval = 5,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let fileURL = URL(fileURLWithPath: "\(file)", isDirectory: false)
        let directoryURL = snapshotDirectoryURL(for: fileURL)

        let failure = verifySnapshot(
            matching: value,
            as: snapshotting,
            named: name,
            record: recording,
            snapshotDirectory: directoryURL.path,
            timeout: timeout,
            file: file,
            testName: testName
        )

        if let message = failure {
            XCTFail(message, file: file, line: line)
        }
    }

    /// Returns the snapshot directory to use for the given test case file URL.
    private func snapshotDirectoryURL(for testsFileURL: URL) -> URL {
        let fileName = testsFileURL.deletingPathExtension().lastPathComponent

        return testsFileURL
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent(fileName)
    }
}

@available(iOS 13.0, tvOS 13.0, *)
public extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
    static func imageWithAcceptableInaccuracy(
        drawHierarchyInKeyWindow: Bool = false,
        layout: SwiftUISnapshotLayout = .sizeThatFits,
        traits: UITraitCollection = .init()
    ) -> Snapshotting {
        Snapshotting.image(
            drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
            precision: SnapshotTestsSetup.Constants.precisionDefaultValue,
            subpixelThreshold: SnapshotTestsSetup.Constants.subpixelThresholdDefaultValue,
            layout: layout,
            traits: traits
        )
    }
}
