//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import ProjectDescription

/// An enum that represents a set of scripts that can be run as part of the project build process.
public enum Scripts {
    case swiftFormat
    case swiftLint
    case crashlytics

    /// Returns the corresponding `TargetScript` for the script case.
    ///
    /// - Returns: A `TargetScript` object with the corresponding script command and metadata.
    func getScript() -> TargetScript {
        switch self {
        case .swiftFormat:
            .pre(script: .swiftFormat,
                 name: "Run SwiftFormat",
                 basedOnDependencyAnalysis: false)
        case .swiftLint:
            .pre(script: .swiftLint,
                 name: "Run SwiftLint",
                 basedOnDependencyAnalysis: false)
        case .crashlytics:
            .pre(script: .crashlyticsSPM,
                 name: "Run Crashlytics",
                 basedOnDependencyAnalysis: false)
        }
    }
}

public extension TargetScript {
    // Default pre-build scripts for targets
    static let defaultScript: [TargetScript] = [
        Scripts.swiftLint.getScript(),
        Scripts.swiftFormat.getScript()
    ]
}

// swiftlint:disable line_length

public extension String {
    // Script to run SwiftLint
    static let swiftLint = """
    # Apple Silicon Homebrew directory
    export PATH="$PATH:/opt/homebrew/bin"

    if which swiftlint >/dev/null; then
        swiftlint --config ../.swiftlint.yml
    else
        echo "SwiftLint is not installed. Please run 'make setup'"
        exit 1
    fi
    """

    // Script to run SwiftFormat
    static let swiftFormat = """
    # Apple Silicon Homebrew directory
    export PATH="$PATH:/opt/homebrew/bin"

    if which swiftformat >/dev/null; then
        swiftformat --swiftversion \(Environment.swiftVersion) --verbose --exclude "**/*.entitlements" .
    else
        echo "warning: SwiftFormat not installed. Please run 'make setup'"
        exit 1
    fi
    """

    // Script to upload Crashlytics symbols with SPM
    static let crashlyticsSPM = """
    if [ "${CONFIGURATION}" != "Debug" ]; then
         "Tuist/Dependencies/SwiftPackageManager/.build/checkouts/firebase-ios-sdk/Crashlytics/run" "Tuist/Dependencies/SwiftPackageManager/.build/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols" -gsp ./Resources/GoogleService-Info.plist -p ios ${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
    fi
    """

    // Script to upload Crashlytics symbols with CocoaPods
    static let crashlyticsPod = """
    if [ "${CONFIGURATION}" != "Debug" ]; then
        ${BUILD_DIR%Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run
    fi
    """
}

// swiftlint:enable line_length
