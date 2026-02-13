//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

public extension View {
    /// Sets the text style for all `Text` in the view. This modifier works recursively like `font`.
    ///
    /// - Parameter textStyle: text style to use for all text in this view
    /// - Returns: A view with the specified textStyle set
    func textStyle(_ textStyle: TextStyle) -> some View {
        modifier(TextStyleModifier(textStyle))
    }

    /// Applies the default app theme colors for background and text.
    ///
    /// - Returns: A view using `Color.aBackground` and `Color.aPrimary`.
    func appThemeColors() -> some View {
        background(Color.aBackground)
            .foregroundStyle(Color.aPrimary)
    }
}

/// A view modifier that applies a text style to the view's text.
struct TextStyleModifier: ViewModifier {
    /// The text style to apply.
    private var textStyle: TextStyle

    /// Creates a new instance of the modifier with the specified text style.
    /// - Parameter textStyle: The text style to apply to the view's text.
    init(_ textStyle: TextStyle) {
        self.textStyle = textStyle
    }

    /// Applies the text style to the view's text.
    func body(content: Content) -> some View {
        let typography = textStyle.typography
        #if os(macOS)
        return content
            .font(Font(typography.font))
        #else
        return content
            .font(Font(typography.font))
            .lineSpacing(typography.lineSpacing)
        #endif
    }
}
