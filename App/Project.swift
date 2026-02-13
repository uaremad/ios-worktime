//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

@preconcurrency import ProjectDescription
import ProjectDescriptionHelpers

// Set the name of the project
let name = "App"

// Set the external packages used in the project
let packages: [Package] = [
    .snapshotKit
]

// Set the dependencies of the app target
let dependencies: [TargetDependency] = [
    .coreDataKit,
    .pdfGenerator
]

// Creates the project
let project = Project(
    name: name,
    options: .options(
        automaticSchemesOptions: .disabled,
        defaultKnownRegions: ["de", "en", "es", "fr", "la", "pt", "ru", "ar", "da", "fi", "ja", "nb", "nl", "pl", "sv", "tr"],
        developmentRegion: "en"
    ),
    packages: packages,
    settings: .projectSettings,
    targets: [
        .appTarget(
            name: name,
            productName: Environment.productName,
            scripts: TargetScript.defaultScript,
            sources: ["Sources/**"],
            resources: [
                .glob(
                    pattern: "Resources/**",
                    excluding: [
                        "Resources/iOS/**",
                        "Resources/macOS/**"
                    ]
                ),
                .glob(
                    pattern: "Resources/iOS/**",
                    inclusionCondition: .when([.ios])
                ),
                .glob(
                    pattern: "Resources/macOS/**",
                    inclusionCondition: .when([.macos])
                )
            ],
            dependencies: dependencies,
            settings: .appTargetSettings,
            environment: [
                "OS_ACTIVITY_MODE": "disable",
                "DISABLE_DIAMOND_PROBLEM_DIAGNOSTIC": "YES"
            ],
            coreDataModels: [CoreDataModel.coreDataModel(
                "CoreData/Worktime.xcdatamodeld"
            )]
        ),
        .target(
            name: "WorktimeWatch",
            destinations: [.appleWatch],
            product: .app,
            bundleId: "com.jandamerau.worktime-watch",
            deploymentTargets: .watchOS("26.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "Worktime",
                    "WKApplication": true
                ]
            ),
            sources: ["Watch/Sources/**"],
            resources: [],
            dependencies: [],
            settings: .targetSettings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "CODE_SIGN_ENTITLEMENTS": "Watch/Entitlements/Watch.entitlements",
                    "PRODUCT_NAME": "Worktime"
                ]
            )
        ),
        .target(
            name: "WorktimeWidgetiOS",
            destinations: [.iPhone, .iPad],
            product: .appExtension,
            bundleId: "com.jandamerau.worktime-ios.widget",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "Worktime Widget iOS",
                    "NSExtension": [
                        "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
                        "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).WorktimeiOSWidgetBundle"
                    ]
                ]
            ),
            sources: ["Widget/Sources/iOS/**"],
            resources: ["Widget/Resources/**"],
            settings: .targetSettings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "CODE_SIGN_ENTITLEMENTS": "Widget/Entitlements/Widget.iOS.entitlements",
                    "PRODUCT_NAME": "Worktime Widget iOS",
                    "SKIP_INSTALL": "YES"
                ]
            )
        ),
        .target(
            name: "WorktimeWidgetMac",
            destinations: [.mac],
            product: .appExtension,
            bundleId: "com.jandamerau.worktime-mac.widget",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "Worktime Widget Mac",
                    "NSExtension": [
                        "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
                        "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).WorktimeMacWidgetBundle"
                    ]
                ]
            ),
            sources: ["Widget/Sources/macOS/**"],
            resources: ["Widget/Resources/**"],
            settings: .targetSettings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "CODE_SIGN_ENTITLEMENTS": "Widget/Entitlements/Widget.macOS.entitlements",
                    "PRODUCT_NAME": "Worktime Widget Mac",
                    "SKIP_INSTALL": "YES"
                ]
            )
        ),
        // Add the app test target
        .appTestTarget(
            name: name,
            dependencies: [
                .snapshotKit
            ]
        )
    ]
)
