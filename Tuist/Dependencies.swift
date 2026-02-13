//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import ProjectDescription
import ProjectDescriptionHelpers

let dependencies = Dependencies(
    swiftPackageManager: SwiftPackageManagerDependencies(
        [],
        baseSettings: Settings.settings(
            base: [
                "APPLICATION_EXTENSION_API_ONLY": "YES" // Build setting that allows only App Extension API calls
            ],
            configurations: [
                .debug(name: "Debug"), // Debug configuration
                .release(name: "Staging"), // Staging configuration
                .release(name: "Release") // Release configuration
            ]
        )
    ),
    platforms: Environment.platforms // Target platforms for the project
)
