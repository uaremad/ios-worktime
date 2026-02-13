//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

/// Wrapper to get some app related strings at one place.
public struct AppInfo {
    /// Returns the official app name, defined in your project data.
    public var appName: String {
        readFromInfoPlist(withKey: "CFBundleName") ?? "(unknown app name)"
    }

    /// Return the official app display name, eventually defined in your 'infoplist'.
    public var displayName: String {
        readFromInfoPlist(withKey: "CFBundleDisplayName") ?? "(unknown app display name)"
    }

    /// Returns the official version, defined in your project data.
    public var version: String {
        readFromInfoPlist(withKey: "CFBundleShortVersionString") ?? "(unknown app version)"
    }

    /// Returns the official 'build', defined in your project data.
    public var build: String {
        readFromInfoPlist(withKey: "CFBundleVersion") ?? "(unknown build number)"
    }

    /// Returns the minimum OS version defined in your project data.
    public var minimumOSVersion: String {
        readFromInfoPlist(withKey: "MinimumOSVersion") ?? "(unknown minimum OSVersion)"
    }

    /// Returns the copyright notice eventually defined in your project data.
    public var copyrightNotice: String {
        readFromInfoPlist(withKey: "NSHumanReadableCopyright") ?? "(unknown copyright notice)"
    }

    /// Returns the official bundle identifier defined in your project data.
    public var bundleIdentifier: String {
        readFromInfoPlist(withKey: "CFBundleIdentifier") ?? "(unknown bundle identifier)"
    }

    /// Returns the developer team identifier.
    public var developer: String { "NT8P3SU78B" }

    /// Returns the App Store identifier for the current platform.
    public var appstoreId: String {
        readFromInfoPlist(withKey: "AppStoreId") ?? ""
    }

    /// Returns the App Store identifier for the iOS/iPadOS app.
    ///
    /// This is used to create cross-platform links (e.g. from macOS to the iOS App Store page).
    public var iosAppStoreId: String? {
        let rawValue = readFromInfoPlist(withKey: "IOSAppStoreId")?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let rawValue, rawValue.isEmpty == false else {
            return nil
        }
        return rawValue
    }

    /// Returns the App Store product page URL for the iOS/iPadOS app, if it can be constructed.
    public var iosAppStoreURL: URL? {
        guard let iosAppStoreId, iosAppStoreId.allSatisfy(\.isNumber) else {
            return nil
        }
        return URL(string: "https://apps.apple.com/app/id\(iosAppStoreId)")
    }

    /// Returns the CloudKit container identifier used for iCloud sync.
    public var cloudContainerId: String {
        readFromInfoPlist(withKey: "CloudContainerId") ?? "iCloud.com.jandamerau.worktime"
    }

    /// Defines whether the website should open outside the app.
    public static let openWebsiteExternal: Bool = false

    // MARK: - Private stuff

    // lets hold a reference to the Info.plist of the app as Dictionary
    private let infoPlistDictionary = Bundle.main.infoDictionary

    /// Retrieves and returns associated values (of Type String) from info.Plist of the app.
    private func readFromInfoPlist(withKey key: String) -> String? {
        infoPlistDictionary?[key] as? String
    }

    public init() {}
}
