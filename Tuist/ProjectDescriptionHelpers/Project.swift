//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

/// A convenience method for creating a project with a framework target.
///
/// - Parameters:
///   - name: The name of the project and framework target.
///   - packages: The Swift packages that the project depends on.
///   - settings: The build settings for the project.
///   - sources: The source files for the framework target.
///   - resources: The resource files for the framework target.
///   - dependencies: The target dependencies for the framework target.
///   - testResources: The resource files for the test target.
///   - testDependencies: The target dependencies for the test target.
///   - additionalTargets: Additional targets to add to the project.
///
/// - Returns: A new project with a framework target.
public extension Project {
    static func framework(
        name: String,
        packages: [Package] = [],
        settings: Settings? = .projectSettings,
        sources: SourceFilesList? = nil,
        resources: ResourceFileElements? = nil,
        dependencies: [TargetDependency] = [],
        testResources: ResourceFileElements? = nil,
        testDependencies: [TargetDependency] = [],
        additionalTargets: [Target] = []
    ) -> Project {
        Project(
            name: name,
            options: .options(
                automaticSchemesOptions: .disabled
            ),
            packages: packages,
            settings: settings,
            targets: [
                .frameworkTarget(
                    name: name,
                    sources: sources,
                    resources: resources,
                    scripts: TargetScript.defaultScript,
                    dependencies: dependencies
                ),
                .testTarget(
                    name: name,
                    resources: testResources,
                    dependencies: testDependencies
                )
            ] + additionalTargets
        )
    }
}
