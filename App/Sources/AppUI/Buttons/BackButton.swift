//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

/// A reusable back button for SwiftUI navigation, using a custom icon.
///
/// The `BackButton` view displays a tappable back arrow (from the app's assets) and triggers a custom action.
/// Use this component when you need a back button **outside of toolbars** (for example, in custom headers, onboarding screens,
/// overlays, or other custom layouts where a navigation toolbar is not available or desired).
///
/// For toolbar-based navigation, see `ToolbarBackItem`.
///
/// The accessibility label is automatically localized (e.g., "Back" for English, "Zurück" for German), but can be overridden
/// with a custom label if needed. The button's position can be adjusted by providing an optional offset.
///
/// Example usage:
///
///     .navigationBarItems(leading: BackButton { navigation.pop() })
///     .navigationBarBackButtonHidden(true)
///
/// - Parameters:
///   - accessibilityLabel: (Optional) Custom accessibility label for the button. If nil, a localized "Back" label is used.
///   - offset: (Optional) A custom offset for the button, e.g. to tweak vertical or horizontal positioning. Default is `.zero`.
///   - action: Closure executed when the button is tapped.
///
/// - Note:
///   Use `BackButton` when you are **not** using the SwiftUI toolbar system (`.toolbar { ... }`).
///   For toolbar-based navigation, prefer `ToolbarBackItem`.
public struct BackButton: View {
    /// The action to perform when the button is tapped.
    let action: () -> Void

    /// Optional custom accessibility label.
    let accessibilityLabel: String?

    /// Optional offset for button positioning.
    let offset: CGSize

    /// Provides a localized accessibility label ("Back" or "Zurück") based on the device's language settings.
    private var localizedBackLabel: String {
        let langCode = Locale.current.language.languageCode?.identifier ?? "en"
        return langCode.starts(with: "de") ? "Zurück" : "Back"
    }

    /// The view body.
    public var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .resizable()
                .scaledToFit()
                .frame(width: .spacingM, height: .spacingM)
                .contentShape(Rectangle())
        }
        .offset(offset)
        .accessibilityLabel(Text(accessibilityLabel ?? localizedBackLabel))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("toolbarBackButton")
        .foregroundStyle(Color.aPrimary)
        .background(Color.aBackground)
    }

    /// Initializes a new back button.
    ///
    /// - Parameters:
    ///   - accessibilityLabel: Optional custom accessibility label. If `nil`, the label is localized automatically.
    ///   - offset: Optional custom offset for the button. Default is `.zero`.
    ///   - action: Closure to execute when the button is tapped.
    ///
    /// - Important:
    ///   Use this initializer when you need a back button **outside of toolbars** (e.g. in custom layouts, onboarding, overlays).
    ///   For navigation toolbars, use `ToolbarBackItem`.
    public init(
        accessibilityLabel: String? = nil,
        offset: CGSize = .zero,
        action: @escaping () -> Void
    ) {
        self.action = action
        self.accessibilityLabel = accessibilityLabel
        self.offset = offset
    }
}
