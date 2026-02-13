//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

import SwiftUI

#if os(macOS)
public typealias TypeFont = NSFont
#else
public typealias TypeFont = UIFont
#endif

/// A model that represents a typography style, which includes font, font size, line height, and dynamic type reference.
public struct Typography {
    public let name: String
    public let font: TypeFont
    public let baseFontSize: Double
    public let baseLineHeight: Double

    // MARK: - Getting font properties

    /// The font size in points of the typography style.
    public var fontSize: Double {
        Double(baseFontSize)
    }

    /// The line height in points of the typography style.
    public var lineHeight: Double {
        (fontSize / baseFontSizeScaledForCurrentDevice) * baseLineHeight
    }

    /// Creates a new `Typography` instance with the given properties.
    ///
    /// - Parameters:
    ///   - name: The name of the typography.
    ///   - font: The `Font` object representing the font to use for the typography.
    ///   - baseFontSize: The base font size to use for the typography.
    ///   - baseLineHeight: The base line height to use for the typography.
    ///
    /// - Returns: A new `Typography` instance with the given properties.
    public init(
        name: String,
        font: TypeFont,
        baseFontSize: Double,
        baseLineHeight: Double
    ) {
        self.name = name
        self.font = font
        self.baseFontSize = baseFontSize
        self.baseLineHeight = baseLineHeight
    }
}

extension Typography {
    /// The amount of spacing between lines in points based on the line height and font metrics.
    var lineSpacing: Double {
        #if os(macOS)
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle // swiftlint:disable:this force_cast
        paragraphStyle.lineSpacing = 0
        let attributes: [NSAttributedString.Key: Any] = [.font: self, .paragraphStyle: paragraphStyle]
        let attributedString = NSAttributedString(string: " ", attributes: attributes)
        return ceil(attributedString.boundingRect(with: .zero, options: .usesLineFragmentOrigin).height)
        #else
        max(lineHeight - font.lineHeight, 0)
        #endif
    }

    /// The base font size scaled for the current device.
    private var baseFontSizeScaledForCurrentDevice: Double {
        baseFontSize
    }
}
