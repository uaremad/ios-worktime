//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import ProjectDescription

struct Dependency {}

/// Extension for TargetDependency to define different
/// dependencies used in the project.
///
public extension TargetDependency {
    // Own Modules
    static var coreDataKit: Self { .project(target: "CoreDataKit", path: .relativeToRoot("Modules/CoreDataKit")) }
    /// The PDF generation framework module.
    static var pdfGenerator: Self { .project(target: "PDFGenerator", path: .relativeToRoot("Modules/PDFGenerator")) }

    // Third Party
    static var snapshotKit: Self { .package(product: "SnapshotKit") }
}
