//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

@preconcurrency import ProjectDescription

public enum Environment {
    // The name of the app.
    public static let appName = "Worktime"
    // The name of the product.
    public static let productName = "Worktime"
    // The name of the organization.
    public static let organizationName = "Jan-Hendrik Damerau"
    // The developer team ID.
    public static let developerTeamId = "NT8P3SU78B"
    // The deployment targets of the app.
    public static let deploymentTarget: DeploymentTargets = .multiplatform(
        iOS: "26.0",
        macOS: "26.0"
    )
    // The platform of the app.
    public static let platform: Platform = .iOS
    public static let platforms: [Platform] = [.iOS, .macOS]
    public static let destinations: Destinations = [.iPhone, .iPad, .mac]
    // The Swift version to use.
    public static let swiftVersion = "6.2"
}

/// The BundleIdentifier enum defines the bundle identifiers to use for
/// the app in different modes, such as release, development, and staging.
public enum BundleIdentifier {
    // The bundle identifier to use for the app in release mode.
    public static let appRelease = "com.jandamerau.worktime-ios"
    // The bundle identifier to use for the app in developer mode.
    public static let appDevelopment = "com.jandamerau.worktime-ios"
    // The bundle identifier to use for the app in staging / testflight mode.
    public static let appStaging = "com.jandamerau.worktime-ios"
    // The bundle identifier to use for the macOS app.
    public static let appMac = "com.jandamerau.worktime-mac"
}
