//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import ProjectDescription

/// An enum containing functions to create Xcode schemes for the app.
public enum Schemes {
    /// Creates Xcode schemes for the app.
    ///
    /// - Returns: An array of Xcode schemes.
    public static func makeAppSchemes() -> [Scheme] {
        // Create a debug scheme for the app.

        let debugScheme = Scheme.scheme(
            name: "Worktime",
            shared: true,
            buildAction: .buildAction(
                targets: [.project(path: "App", target: "App")]
            ),
            testAction: .testPlans([
                .relativeToRoot("App/TestPlans/AllTests.xctestplan")
            ], configuration: .configuration("Debug")),
            runAction: .runAction(
                configuration: .configuration("Debug"),
                executable: .project(path: "App", target: "App"),
                arguments: .arguments(environmentVariables: ["OS_ACTIVITY_MODE": "disable"])
            ),
            archiveAction: .archiveAction(configuration: .configuration("Release")),
            profileAction: .profileAction(configuration: .configuration("Debug")),
            analyzeAction: .analyzeAction(configuration: .configuration("Debug"))
        )

        // Create a staging scheme for the app.
        let stagingScheme = Scheme.scheme(
            name: "Staging",
            shared: true,
            buildAction: .buildAction(
                targets: [.project(path: "App", target: "App")]
            ),
            testAction: .testPlans([
                .relativeToRoot("App/TestPlans/AllTests.xctestplan")
            ], configuration: .configuration("Staging")),
            runAction: .runAction(configuration: .configuration("Staging")),
            archiveAction: .archiveAction(configuration: .configuration("Staging")),
            profileAction: .profileAction(configuration: .configuration("Staging")),
            analyzeAction: .analyzeAction(configuration: .configuration("Staging"))
        )

        // Create a release scheme for the app.
        let releaseScheme = Scheme.scheme(
            name: "Release",
            shared: true,
            buildAction: .buildAction(
                targets: [.project(path: "App", target: "App")]
            ),
            testAction: .testPlans([
                .relativeToRoot("App/TestPlans/AllTests.xctestplan")
            ], configuration: .configuration("Release")),
            runAction: .runAction(configuration: .configuration("Release")),
            archiveAction: .archiveAction(configuration: .configuration("Release")),
            profileAction: .profileAction(configuration: .configuration("Release")),
            analyzeAction: .analyzeAction(configuration: .configuration("Release"))
        )

        return [
            debugScheme,
            stagingScheme,
            releaseScheme
        ]
    }
}
