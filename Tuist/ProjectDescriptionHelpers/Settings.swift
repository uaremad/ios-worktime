//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import ProjectDescription

public extension Settings {
    static var projectSettings: Self {
        .settings(
            base: .projectBaseSettings,
            configurations: [
                .debug(name: "Debug", settings: .projectSettings(for: .debug)),
                .release(name: "Staging", settings: .projectSettings(for: .staging)),
                .release(name: "Release", settings: .projectSettings(for: .release))
            ],
            defaultSettings: .recommended
        )
    }

    static var hostSettings: Self {
        .settings(
            base: .projectBaseSettings,
            configurations: [
                .debug(name: "Debug", settings: .projectSettings(for: .debug))
            ],
            defaultSettings: .recommended
        )
    }

    static func targetSettings(base: SettingsDictionary? = nil) -> Self {
        .settings(
            base: base ?? [
                "APPLICATION_EXTENSION_API_ONLY": "YES"
            ],
            configurations: [
                .debug(name: "Debug", settings: .targetSettings(for: .debug)),
                .release(name: "Staging", settings: .targetSettings(for: .staging)),
                .release(name: "Release", settings: .targetSettings(for: .release))
            ],
            defaultSettings: .essential(excluding: ["CODE_SIGN_IDENTITY"])
        )
    }

    static var appTargetSettings: Self {
        .settings(
            base: [:],
            configurations: [
                .debug(name: "Debug", settings: .appTargetSettings(for: .debug)),
                .release(name: "Staging", settings: .appTargetSettings(for: .staging)),
                .release(name: "Release", settings: .appTargetSettings(for: .release))
            ],
            defaultSettings: .essential(excluding: ["CODE_SIGN_IDENTITY"])
        )
    }
}

extension SettingsDictionary {
    static var projectBaseSettings: SettingsDictionary {
        [
            "CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED": "YES",
            "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "NO",
            "CURRENT_PROJECT_VERSION": .appBuildNumber,
            "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
            "DEVELOPMENT_TEAM": "\(Environment.developerTeamId)",
            "DYLIB_INSTALL_NAME_BASE": "@rpath",
            "MARKETING_VERSION": .appVersion
        ]
    }

    static func projectSettings(for config: Config) -> SettingsDictionary {
        var settings: SettingsDictionary = switch config {
        case .debug:
            [
                "CODE_SIGN_IDENTITY": "Apple Development",
                "CODE_SIGN_STYLE": "Manual",
                "SWIFT_OPTIMIZATION_LEVEL": "-Onone"
            ]
        case .staging, .release:
            [
                "CLANG_ENABLE_CODE_COVERAGE": "NO",
                "CODE_SIGN_IDENTITY": "Apple Distribution",
                "CODE_SIGN_STYLE": "Manual",
                "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
                "GCC_GENERATE_DEBUGGING_SYMBOLS": "YES",
                "SWIFT_COMPILATION_MODE": "wholemodule",
                "SWIFT_OPTIMIZATION_LEVEL": "-O"
            ]
        }

        settings.merge(swiftActiveCompilationConditions(for: config))

        return settings
    }

    static func swiftActiveCompilationConditions(for config: Config) -> SettingsDictionary {
        switch config {
        case .debug:
            ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG DEVELOPMENT"]
        case .staging, .release:
            ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "RELEASE PRODUCTION"]
        }
    }

    static func targetSettings(for config: Config) -> SettingsDictionary {
        var settings: SettingsDictionary = [
            "CODE_SIGN_STYLE": "Manual",
            "SKIP_INSTALL": "YES"
        ]

        switch config {
        case .debug:
            break
        case .staging, .release:
            settings["DEBUG_INFORMATION_FORMAT"] = "dwarf-with-dsym"
            settings["GCC_GENERATE_DEBUGGING_SYMBOLS"] = "YES"
        }

        return settings
    }

    static func appTargetSettings(for config: Config) -> SettingsDictionary {
        var settings: SettingsDictionary = [
            "CODE_SIGN_STYLE": "Manual",
            "SWIFT_OBJC_BRIDGING_HEADER": "Sources/Bootstrap/Bridging-Header.h"
        ]

        switch config {
        case .debug:
            settings["CODE_SIGN_STYLE"] = "Automatic"
            settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
            settings["CODE_SIGN_ENTITLEMENTS[sdk=iphone*]"] = "Entitlements/App.development.entitlements"
            settings["CODE_SIGN_ENTITLEMENTS[sdk=macosx*]"] = "Entitlements/App.macos.entitlements"
            settings["PRODUCT_BUNDLE_IDENTIFIER"] = "\(BundleIdentifier.appDevelopment)"
            settings["PRODUCT_BUNDLE_IDENTIFIER[sdk=macosx*]"] = "\(BundleIdentifier.appMac)"
            settings["PRODUCT_DISPLAY_NAME"] = "\(Environment.productName) Dev"
            settings["PROVISIONING_PROFILE_SPECIFIER[sdk=iphone*]"] = ""
            settings["PROVISIONING_PROFILE_SPECIFIER[sdk=macosx*]"] = ""
            settings["GCC_PREPROCESSOR_DEFINITIONS"] = "DEBUG=1 $(inherited)"
        case .staging:
            settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
            settings["CODE_SIGN_ENTITLEMENTS[sdk=iphone*]"] = "Entitlements/App.staging.entitlements"
            settings["CODE_SIGN_ENTITLEMENTS[sdk=macosx*]"] = "Entitlements/App.macos.entitlements"
            settings["DEBUG_INFORMATION_FORMAT"] = "dwarf-with-dsym"
            settings["GCC_GENERATE_DEBUGGING_SYMBOLS"] = "YES"
            settings["PRODUCT_BUNDLE_IDENTIFIER"] = "\(BundleIdentifier.appStaging)"
            settings["PRODUCT_BUNDLE_IDENTIFIER[sdk=macosx*]"] = "\(BundleIdentifier.appMac)"
            settings["PRODUCT_DISPLAY_NAME"] = "\(Environment.productName) QA"
            settings["PROVISIONING_PROFILE_SPECIFIER[sdk=iphone*]"] = "\(Environment.productName) iOS TestFlight"
            settings["PROVISIONING_PROFILE_SPECIFIER[sdk=macosx*]"] = ""
        case .release:
            settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
            settings["CODE_SIGN_ENTITLEMENTS[sdk=iphone*]"] = "Entitlements/App.release.entitlements"
            settings["CODE_SIGN_ENTITLEMENTS[sdk=macosx*]"] = "Entitlements/App.macos.entitlements"
            settings["DEBUG_INFORMATION_FORMAT"] = "dwarf-with-dsym"
            settings["GCC_GENERATE_DEBUGGING_SYMBOLS"] = "YES"
            settings["PRODUCT_BUNDLE_IDENTIFIER"] = "\(BundleIdentifier.appRelease)"
            settings["PRODUCT_BUNDLE_IDENTIFIER[sdk=macosx*]"] = "\(BundleIdentifier.appMac)"
            settings["PRODUCT_DISPLAY_NAME"] = "\(Environment.productName) "
            settings["PROVISIONING_PROFILE_SPECIFIER[sdk=iphone*]"] = "\(Environment.productName) iOS Distribution"
            settings["PROVISIONING_PROFILE_SPECIFIER[sdk=macosx*]"] = ""
        }

        settings["EXCLUDED_SOURCE_FILE_NAMES"] = .excludedSourceFiles(for: config)

        return settings
    }
}

/// Extension for `SettingValue` that provides computed properties for commonly used settings values.
extension SettingValue {
    /// Returns a `SettingValue` that represents the list of excluded source files based on the given `config`.
    ///
    /// - Parameter config: The `Config` to use.
    /// - Returns: The `SettingValue` that represents the list of excluded source files.
    static func excludedSourceFiles(for config: Config) -> SettingValue {
        let excludedFiles: [String] = switch config {
        case .release:
            []
        case .debug, .staging:
            []
        }
        let filenames = excludedFiles.map { "\"\($0).swift\"" }.joined(separator: " ")
        return SettingValue(stringLiteral: filenames)
    }

    /// Returns a `SettingValue` that represents the app version.
    ///
    /// The app version is read from a file named `.app-version` in the current directory.
    /// The file must contain a single line with the app version as its contents.
    ///
    /// - Returns: The `SettingValue` that represents the app version.
    static var appVersion: Self {
        let fileName = ".app-version"
        let rootPath = FileManager.default.currentDirectoryPath
        do {
            let value = try String(contentsOfFile: rootPath + "/" + fileName)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return .string(value)
        } catch {
            fatalError("Ensure the file \"\(fileName)\" exists and is readable!")
        }
    }

    /// Returns a `SettingValue` that represents the app build number.
    ///
    /// The app build number is read from a file named `.app-buildnumber` in the current directory.
    /// The file must contain a single line with the app build number as its contents.
    ///
    /// - Returns: The `SettingValue` that represents the app build number.
    static var appBuildNumber: Self {
        let fileName = ".app-buildnumber"
        let rootPath = FileManager.default.currentDirectoryPath
        do {
            let value = try String(contentsOfFile: rootPath + "/" + fileName)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return .string(value)
        } catch {
            fatalError("Ensure the file \"\(fileName)\" exists and is readable!")
        }
    }
}
