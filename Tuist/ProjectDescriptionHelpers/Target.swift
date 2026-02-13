//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import ProjectDescription

/// The extension of `Target` enum that contains factory methods for creating app targets, app test targets, framework targets and test targets.
public extension Target {
    /// Creates an app target with the given properties.
    ///
    /// - Parameters:
    ///   - name: The name of the target.
    ///   - productName: The name of the product.
    ///   - scripts: The build scripts of the target.
    ///   - sources: The source files of the target.
    ///   - resources: The resource files of the target.
    ///   - dependencies: The dependencies of the target.
    ///   - settings: The build settings of the target.
    ///   - environment: The environment variables used by the target.
    ///
    /// - Returns: An instance of the `Target` enum representing an app target.
    static func appTarget(
        name: String,
        productName: String? = nil,
        destinations: Destinations = Environment.destinations,
        scripts: [TargetScript] = [],
        sources: SourceFilesList? = nil,
        resources: ResourceFileElements? = nil,
        dependencies: [TargetDependency] = [],
        settings: Settings? = nil,
        environment: [String: EnvironmentVariable] = [:],
        coreDataModels: [CoreDataModel] = []
    ) -> Self {
        .target(
            name: name,
            destinations: destinations,
            product: .app,
            productName: productName ?? name,
            bundleId: BundleIdentifier.appRelease,
            deploymentTargets: .default,
            infoPlist: .file(path: "Sources/Info.plist"),
            sources: sources ?? ["Sources/**"],
            resources: resources ?? ["Resources/**"],
            scripts: scripts,
            dependencies: dependencies,
            settings: settings,
            coreDataModels: coreDataModels,
            environmentVariables: environment,
            launchArguments: []
        )
    }

    /// Creates an app test target with the given properties.
    ///
    /// - Parameters:
    ///   - name: The name of the target.
    ///   - resources: The resource files of the target.
    ///   - dependencies: The dependencies of the target.
    ///
    /// - Returns: An instance of the `Target` enum representing an app test target.
    static func appTestTarget(
        name: String,
        resources: ResourceFileElements? = nil,
        dependencies: [TargetDependency] = []
    ) -> Self {
        .target(
            name: "\(name)Tests",
            destinations: Environment.destinations,
            product: .unitTests,
            bundleId: "\(BundleIdentifier.appRelease)Tests",
            deploymentTargets: .default,
            infoPlist: .default,
            sources: ["Tests/**"],
            resources: resources ?? [],
            dependencies: [
                .target(name: name)
            ] + dependencies
        )
    }

    /// Creates a framework target with the given properties.
    ///
    /// - Parameters:
    ///   - name: The name of the target.
    ///   - platform: The target platform.
    ///   - infoPlist: The Info.plist file of the target.
    ///   - sources: The source files of the target.
    ///   - resources: The resource files of the target.
    ///   - scripts: The build scripts of the target.
    ///   - dependencies: The dependencies of the target.
    ///   - coreDataModels: The Core Data models of the target.
    ///
    /// - Returns: An instance of the `Target` enum representing a framework target.
    static func frameworkTarget(
        name: String,
        destinations: Destinations = Environment.destinations,
        infoPlist: InfoPlist = .default,
        sources: SourceFilesList? = nil,
        resources: ResourceFileElements? = nil,
        scripts: [TargetScript] = [],
        dependencies: [TargetDependency] = [],
        coreDataModels: [CoreDataModel] = []
    ) -> Self {
        .target(
            name: name,
            destinations: destinations,
            product: .framework,
            bundleId: "\(BundleIdentifier.appRelease).\(name)Framework",
            deploymentTargets: .default,
            infoPlist: infoPlist,
            sources: sources ?? ["Sources/**"],
            resources: resources ?? ["Resources/**"],
            scripts: scripts,
            dependencies: dependencies,
            coreDataModels: coreDataModels
        )
    }

    /// Creates a test target with the given properties.
    ///
    /// - Parameters:
    ///   - name: The name of the target.
    ///   - platform: The target platform.
    ///   - infoPlist: The Info.plist file of the target.
    ///   - sources: The source files of the target.
    ///   - resources: The resource files of the target.
    ///   - dependencies: The dependencies of the target.
    ///
    /// - Returns: An instance of the `Target` enum representing a test target.
    static func testTarget(
        name: String,
        destinations: Destinations = Environment.destinations,
        infoPlist: InfoPlist = .default,
        sources: SourceFilesList? = nil,
        resources: ResourceFileElements? = nil,
        dependencies: [TargetDependency] = []
    ) -> Self {
        .target(
            name: "\(name)Tests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(BundleIdentifier.appRelease).\(name)FrameworkTests",
            deploymentTargets: .default,
            infoPlist: infoPlist,
            sources: sources ?? ["Tests/**"],
            resources: resources ?? ["Tests/Resources/**"],
            dependencies: [
                .target(name: name)
            ] + dependencies
        )
    }
}

// An extension on `DeploymentTarget` that provides a default target
public extension DeploymentTargets {
    static var `default`: Self {
        Environment.deploymentTarget
    }
}

// An enum that defines different build configurations
enum Config {
    case debug
    case staging
    case release
}
