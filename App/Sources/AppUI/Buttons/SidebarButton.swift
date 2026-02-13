//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if os(macOS)

import SwiftUI

/// A single sidebar button that can be selected.
///
/// This button displays an icon and title, with visual feedback
/// for selection and keyboard focus states.
///
/// Conforms to Equatable to prevent unnecessary re-renders when
/// the SwiftData context changes during sync operations.
struct SidebarButton: View, Equatable {
    /// The localized title shown in the sidebar row.
    let title: String
    /// The icon displayed next to the title.
    let image: Image
    /// A Boolean value that indicates whether the item is selected.
    let isSelected: Bool
    /// A Boolean value that indicates whether the item is focused.
    let isFocused: Bool
    /// The action executed when the button is tapped.
    let action: () -> Void

    /// Compares two sidebar buttons for rendering equality.
    nonisolated static func == (lhs: SidebarButton, rhs: SidebarButton) -> Bool {
        lhs.title == rhs.title &&
            lhs.isSelected == rhs.isSelected &&
            lhs.isFocused == rhs.isFocused
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                Text(title)
                    .lineLimit(1)
                Spacer()
            }
        }
        .buttonStyle(SidebarButtonStyle(isSelected: isSelected))
        .focusable(false)
        .focusEffectDisabled()
    }
}

// MARK: - Sidebar Button Style

public struct SidebarButtonStyle: ButtonStyle {
    /// The maximum width applied to the sidebar button.
    private let maxWidth: CGFloat?
    /// A Boolean value that indicates whether the item is selected.
    private let isSelected: Bool
    /// The corner radius used for the button background.
    let cornerRadius: CGFloat = 8

    /// Creates a sidebar button style for the given selection state.
    /// - Parameters:
    ///   - isSelected: Indicates whether the button is selected.
    ///   - maxWidth: The maximum width for the button content.
    public init(isSelected: Bool, maxWidth: CGFloat? = .infinity) {
        self.maxWidth = maxWidth
        self.isSelected = isSelected
    }

    /// Builds the styled button body.
    /// - Parameter configuration: The button configuration provided by SwiftUI.
    public func makeBody(configuration: Self.Configuration) -> some View {
        SidebarButton(
            configuration: configuration,
            isSelected: isSelected,
            maxWidth: maxWidth,
            cornerRadius: cornerRadius
        )
    }

    private struct SidebarButton: View {
        /// A Boolean value that indicates whether the button is enabled.
        @Environment(\.isEnabled) private var isEnabled
        /// The style configuration provided by SwiftUI.
        let configuration: SidebarButtonStyle.Configuration
        /// A Boolean value that indicates whether the item is selected.
        let isSelected: Bool
        /// The maximum width applied to the button content.
        let maxWidth: CGFloat?
        /// The corner radius used for the button background.
        let cornerRadius: CGFloat

        var body: some View {
            configuration.label
                .textStyle(.button1)
                .fontWeight(.medium)
                .frame(minWidth: 0, maxWidth: maxWidth)
                .foregroundColor(foregroundColor(configuration))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor(configuration))
                        .animation(.easeInOut(duration: 0.15), value: isSelected)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor(configuration), lineWidth: 2)
                )
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        }

        /// Resolves the foreground color for the current state.
        func foregroundColor(_: SidebarButtonStyle.Configuration) -> Color {
            if !isEnabled {
                return disabledForegroundColor
            }

            return isSelected ? selectedForegroundColor : .primary
        }

        /// Resolves the border color for the current state.
        func borderColor(_: SidebarButtonStyle.Configuration) -> Color {
            .clear
        }

        /// Resolves the background color for the current state.
        func backgroundColor(_: SidebarButtonStyle.Configuration) -> Color {
            if !isEnabled {
                return disabledBackgroundColor
            }

            if isSelected {
                return selectedBackgroundColor
            }

            if configuration.isPressed {
                return pressedBackgroundColor
            }

            return .clear
        }

        /// The text color used for disabled state.
        var disabledForegroundColor: Color {
            .secondary
        }

        /// The background color used for disabled state.
        var disabledBackgroundColor: Color {
            .clear
        }

        /// The background color used for pressed state.
        var pressedBackgroundColor: Color {
            selectedBackgroundColor
        }

        /// The background color used for selected state.
        var selectedBackgroundColor: Color {
            Color.accentColor
        }

        /// The foreground color used for selected state.
        var selectedForegroundColor: Color {
            Color.aOnAccentColorBlue
        }
    }
}

#endif
