//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

/// This extension adds convenience properties and methods to the `CGFloat` type.
public extension CGFloat {
    /// Formats the `CGFloat` value as a localized string with decimal separators.
    ///
    /// - Parameter locale: The `Locale` to use for formatting the price. Defaults to the device's current locale.
    /// - Returns: A string containing the formatted value.
    func formattedPrice(for locale: Locale = .current) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.locale = locale

        return numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }

    /// The corner radius for UI components based on the device's screen width.
    static var cornerRadius: CGFloat {
        spacingS
    }

    /// A larger corner radius for prominent UI components.
    static var cornerRadiusLarge: CGFloat {
        spacingM
    }

    /// The margin for UI components based on the device's screen width.
    static var screenMargin: CGFloat {
        spacingM
    }

    // MARK: - Spacings

    /// The smallest spacing value used for minimal separation between UI components.
    static let spacingXXXXS: Self = 2
    /// An additional smaller spacing value used for slight separation between UI components.
    static let spacingXXXS: Self = 4
    /// An extra small spacing value used for moderate separation between UI components.
    static let spacingXXS: Self = 8
    /// A small spacing value used for standard separation between UI components.
    static let spacingXS: Self = 12
    /// A standard spacing value used for typical separation between UI components.
    static let spacingS: Self = 16
    /// A medium spacing value used for moderate separation between UI components.
    static let spacingM: Self = 20
    /// A large spacing value used for significant separation between UI components.
    static let spacingL: Self = 24
    /// An extra large spacing value used for substantial separation between UI components.
    static let spacingXL: Self = 32
    /// An extra extra large spacing value used for considerable separation between UI components.
    static let spacingXXL: Self = 48
    /// The largest spacing value used for maximum separation between UI components.
    static let spacingXXXL: Self = 64
}
