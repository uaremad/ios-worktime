//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

public enum TextStyle: CaseIterable, Identifiable {
    /// A level-1 headline style with the system sans font, font size 24pt and line height 32pt
    case title1

    /// A level-2 headline style with the system sans font, font size 14pt and line height 18pt
    case title2

    /// A level-3 headline style with the system sans font, font size 12pt and line height 14.4pt
    case title3

    /// A button text style with the system sans font, font size 10pt and line height 16pt
    case button1

    /// A tabbar text style with the system sans font, font size 10pt and line height 16pt
    case button2

    /// A body-1 text style with the system sans font, font size 16pt and line height 24pt
    case body1

    /// A body-2 text style with the system sans font, font size 16pt and line height 24pt
    case body2

    /// A body-3 text style with the system sans font, font size 12pt and line height 16pt
    case body3

    /// A tabbar text style with the system sans font, font size 10pt and line height 16pt
    case tabbar

    /// ID for the specific text style
    public var id: Self { self }

    /// Returns the specific typography definition based on the text style.
    public var typography: Typography {
        switch self {
        case .title1:
            Typography(
                name: "Title 1",
                font: .systemFont(ofSize: 24, weight: .black), // .system(size: 24, weight: .bold),
                baseFontSize: 24,
                baseLineHeight: 32
            )
        case .title2:
            Typography(
                name: "Title 2",
                font: .systemFont(ofSize: 17, weight: .bold),
                baseFontSize: 17,
                baseLineHeight: 18
            )
        case .title3:
            Typography(
                name: "Title 3",
                font: .systemFont(ofSize: 14, weight: .bold),
                baseFontSize: 14,
                baseLineHeight: 14.4
            )
        case .button1:
            Typography(
                name: "Button",
                font: .systemFont(ofSize: 17, weight: .bold),
                baseFontSize: 17,
                baseLineHeight: 17
            )
        case .button2:
            Typography(
                name: "Tabbar",
                font: .systemFont(ofSize: 12, weight: .bold),
                baseFontSize: 12,
                baseLineHeight: 12
            )
        case .body1:
            Typography(
                name: "Body 1",
                font: .systemFont(ofSize: 17, weight: .regular),
                baseFontSize: 17,
                baseLineHeight: 24
            )
        case .body2:
            Typography(
                name: "Body 2",
                font: .systemFont(ofSize: 17, weight: .bold),
                baseFontSize: 17,
                baseLineHeight: 24
            )
        case .body3:
            Typography(
                name: "Body 3",
                font: .systemFont(ofSize: 14, weight: .regular),
                baseFontSize: 14,
                baseLineHeight: 16
            )
        case .tabbar:
            Typography(
                name: "Tabbar",
                font: .systemFont(ofSize: 10, weight: .semibold),
                baseFontSize: 10,
                baseLineHeight: 16
            )
        }
    }
}
