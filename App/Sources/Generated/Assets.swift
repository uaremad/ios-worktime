//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if os(iOS)
import UIKit
#endif
#if os(macOS)
import Cocoa
#endif
import SwiftUI

public extension Color {
    static let accentColor = ColorAsset.accentColor.color
    static let aAccentColor = ColorAsset.aAccentColor.color
    static let aAccentColorBlack = ColorAsset.aAccentColorBlack.color
    static let aAccentColorBlue = ColorAsset.aAccentColorBlue.color
    static let aAccentColorGreen = ColorAsset.aAccentColorGreen.color
    static let aAccentColorLess = ColorAsset.aAccentColorLess.color
    static let aAccentColorRed = ColorAsset.aAccentColorRed.color
    static let aAccentColorWhite = ColorAsset.aAccentColorWhite.color
    static let aAccentTextColorBlack = ColorAsset.aAccentTextColorBlack.color
    static let aAccentTextColorWhite = ColorAsset.aAccentTextColorWhite.color
    static let aBackground = ColorAsset.aBackground.color
    static let aColumnEven = ColorAsset.aColumnEven.color
    static let aColumnOdd = ColorAsset.aColumnOdd.color
    static let aDanger = ColorAsset.aDanger.color
    static let aFavorite = ColorAsset.aFavorite.color
    static let aGold = ColorAsset.aGold.color
    static let aListBackground = ColorAsset.aListBackground.color
    static let aOnAccentColorBlack = ColorAsset.aOnAccentColorBlack.color
    static let aOnAccentColorBlue = ColorAsset.aOnAccentColorBlue.color
    static let aOnAccentColorGreen = ColorAsset.aOnAccentColorGreen.color
    static let aOnAccentColorLess = ColorAsset.aOnAccentColorLess.color
    static let aOnAccentColorRed = ColorAsset.aOnAccentColorRed.color
    static let aOnAccentColorWhite = ColorAsset.aOnAccentColorWhite.color
    static let aPrimary = ColorAsset.aPrimary.color
    static let aSuccess = ColorAsset.aSuccess.color
    static let aWarning = ColorAsset.aWarning.color
}

#if os(iOS)
public extension UIColor {
    static let accentColor = ColorAsset.accentColor.uiColor
    static let aAccentColor = ColorAsset.aAccentColor.uiColor
    static let aAccentColorBlack = ColorAsset.aAccentColorBlack.uiColor
    static let aAccentColorBlue = ColorAsset.aAccentColorBlue.uiColor
    static let aAccentColorGreen = ColorAsset.aAccentColorGreen.uiColor
    static let aAccentColorLess = ColorAsset.aAccentColorLess.uiColor
    static let aAccentColorRed = ColorAsset.aAccentColorRed.uiColor
    static let aAccentColorWhite = ColorAsset.aAccentColorWhite.uiColor
    static let aAccentTextColorBlack = ColorAsset.aAccentTextColorBlack.uiColor
    static let aAccentTextColorWhite = ColorAsset.aAccentTextColorWhite.uiColor
    static let aBackground = ColorAsset.aBackground.uiColor
    static let aColumnEven = ColorAsset.aColumnEven.uiColor
    static let aColumnOdd = ColorAsset.aColumnOdd.uiColor
    static let aDanger = ColorAsset.aDanger.uiColor
    static let aFavorite = ColorAsset.aFavorite.uiColor
    static let aGold = ColorAsset.aGold.uiColor
    static let aListBackground = ColorAsset.aListBackground.uiColor
    static let aOnAccentColorBlack = ColorAsset.aOnAccentColorBlack.uiColor
    static let aOnAccentColorBlue = ColorAsset.aOnAccentColorBlue.uiColor
    static let aOnAccentColorGreen = ColorAsset.aOnAccentColorGreen.uiColor
    static let aOnAccentColorLess = ColorAsset.aOnAccentColorLess.uiColor
    static let aOnAccentColorRed = ColorAsset.aOnAccentColorRed.uiColor
    static let aOnAccentColorWhite = ColorAsset.aOnAccentColorWhite.uiColor
    static let aPrimary = ColorAsset.aPrimary.uiColor
    static let aSuccess = ColorAsset.aSuccess.uiColor
    static let aWarning = ColorAsset.aWarning.uiColor
}
#endif

#if os(macOS)
public extension NSColor {
    static let accentColor = ColorAsset.accentColor.nsColor
    static let aAccentColor = ColorAsset.aAccentColor.nsColor
    static let aAccentColorBlack = ColorAsset.aAccentColorBlack.nsColor
    static let aAccentColorBlue = ColorAsset.aAccentColorBlue.nsColor
    static let aAccentColorGreen = ColorAsset.aAccentColorGreen.nsColor
    static let aAccentColorLess = ColorAsset.aAccentColorLess.nsColor
    static let aAccentColorRed = ColorAsset.aAccentColorRed.nsColor
    static let aAccentColorWhite = ColorAsset.aAccentColorWhite.nsColor
    static let aAccentTextColorBlack = ColorAsset.aAccentTextColorBlack.nsColor
    static let aAccentTextColorWhite = ColorAsset.aAccentTextColorWhite.nsColor
    static let aBackground = ColorAsset.aBackground.nsColor
    static let aColumnEven = ColorAsset.aColumnEven.nsColor
    static let aColumnOdd = ColorAsset.aColumnOdd.nsColor
    static let aDanger = ColorAsset.aDanger.nsColor
    static let aFavorite = ColorAsset.aFavorite.nsColor
    static let aGold = ColorAsset.aGold.nsColor
    static let aListBackground = ColorAsset.aListBackground.nsColor
    static let aOnAccentColorBlack = ColorAsset.aOnAccentColorBlack.nsColor
    static let aOnAccentColorBlue = ColorAsset.aOnAccentColorBlue.nsColor
    static let aOnAccentColorGreen = ColorAsset.aOnAccentColorGreen.nsColor
    static let aOnAccentColorLess = ColorAsset.aOnAccentColorLess.nsColor
    static let aOnAccentColorRed = ColorAsset.aOnAccentColorRed.nsColor
    static let aOnAccentColorWhite = ColorAsset.aOnAccentColorWhite.nsColor
    static let aPrimary = ColorAsset.aPrimary.nsColor
    static let aSuccess = ColorAsset.aSuccess.nsColor
    static let aWarning = ColorAsset.aWarning.nsColor
}
#endif

public enum ColorAsset: String, CaseIterable {
    case accentColor = "AccentColor"
    case aAccentColor
    case aAccentColorBlack
    case aAccentColorBlue
    case aAccentColorGreen
    case aAccentColorLess
    case aAccentColorRed
    case aAccentColorWhite
    case aAccentTextColorBlack
    case aAccentTextColorWhite
    case aBackground
    case aColumnEven
    case aColumnOdd
    case aDanger
    case aFavorite
    case aGold
    case aListBackground
    case aOnAccentColorBlack
    case aOnAccentColorBlue
    case aOnAccentColorGreen
    case aOnAccentColorLess
    case aOnAccentColorRed
    case aOnAccentColorWhite
    case aPrimary
    case aSuccess
    case aWarning

    #if os(iOS)
    public var color: Color {
        Color(uiColor)
    }
    #endif

    #if os(macOS)
    public var color: Color {
        Color(nsColor)
    }
    #endif

    #if os(iOS)
    public var uiColor: UIColor {
        guard let color = UIColor(asset: self) else {
            assertionFailure("Unable to load color asset named \(rawValue).")
            return .black
        }
        return color
    }
    #endif

    #if os(macOS)
    public var nsColor: NSColor {
        guard let color = NSColor(asset: self) else {
            assertionFailure("Unable to load color asset named \(rawValue).")
            return .black
        }
        return color
    }
    #endif
}

#if os(iOS)
extension UIColor {
    convenience init?(asset: ColorAsset) {
        let bundle = Bundle.main
        #if os(iOS) || os(tvOS)
        self.init(named: asset.rawValue, in: bundle, compatibleWith: nil)
        #elseif os(watchOS)
        self.init(named: asset.rawValue)
        #endif
    }
}
#endif

#if os(macOS)
extension NSColor {
    convenience init?(asset: ColorAsset) {
        let bundle = Bundle.main
        self.init(named: NSColor.Name(asset.rawValue), bundle: bundle)
    }
}
#endif

public extension Image {
    static let icon = ImageAsset.icon.image
}

#if os(macOS)
public extension NSImage {
    static let icon = ImageAsset.icon.nsImage
}
#endif

public enum ImageAsset: String, CaseIterable {
    case icon = "Icon"

    #if os(iOS)
    public var image: Image {
        .init(uiImage: uiImage)
    }

    public var uiImage: UIImage {
        let bundle = Bundle.main
        #if os(iOS) || os(tvOS)
        let image = UIImage(named: rawValue, in: bundle, compatibleWith: nil)
        #elseif os(watchOS)
        let image = UIImage(named: rawValue)
        #endif
        guard let result = image else {
            fatalError("Unable to load image asset named \(rawValue).")
        }
        return result
    }
    #endif

    #if os(macOS)
    public var image: Image {
        .init(nsImage: nsImage)
    }

    public var nsImage: NSImage {
        let bundle = Bundle.main
        guard let image = bundle.image(forResource: NSImage.Name(rawValue)) else {
            fatalError("Unable to load image asset named \(rawValue).")
        }
        return image
    }
    #endif
}
