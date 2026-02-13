//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if os(macOS)
public struct AccentButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        AccentButton(configuration: configuration)
    }

    private struct AccentButton: View {
        @Environment(\.isEnabled) private var isEnabled
        let configuration: ButtonStyleConfiguration

        var body: some View {
            configuration.label
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .foregroundStyle(foregroundColor.opacity(configuration.isPressed ? 0.65 : 1))
                .background(backgroundColor.opacity(configuration.isPressed ? 0.85 : 1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }

        private var foregroundColor: Color {
            isEnabled ? Color.white : Color.secondary.opacity(0.6)
        }

        private var backgroundColor: Color {
            let baseTint = Color.accentColor
            return isEnabled ? baseTint : Color.aListBackground.opacity(0.35)
        }
    }
}
#endif

public extension View {
    @ViewBuilder
    func accentButtonStyle() -> some View {
        #if os(macOS)
        buttonStyle(AccentButtonStyle())
            .focusable(false)
            .focusEffectDisabled()
        #else
        // iOS bleibt nativ (Glass Effect bleibt erhalten)
        font(.subheadline)
        #endif
    }
}
