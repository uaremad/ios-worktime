//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

public struct PrimaryButtonStyle: ButtonStyle {
    public enum Size {
        case `default`, small
    }

    private let height: CGFloat
    private let cornerRadius: CGFloat = 8
    private let maxWidth: CGFloat?

    public init(size: Size = .default, maxWidth: CGFloat? = .infinity) {
        self.maxWidth = maxWidth
        switch size {
        case .default:
            height = 48
        case .small:
            height = 32
        }
    }

    public func makeBody(configuration: Self.Configuration) -> some View {
        PrimaryButton(
            configuration: configuration,
            height: height,
            cornerRadius: cornerRadius,
            maxWidth: maxWidth
        )
    }

    private struct PrimaryButton: View {
        @Environment(\.isEnabled) private var isEnabled
        let configuration: PrimaryButtonStyle.Configuration
        let height: CGFloat
        let cornerRadius: CGFloat
        let maxWidth: CGFloat?

        var body: some View {
            configuration.label
                .textStyle(.button1)
                .fontWeight(.medium)
                .frame(minWidth: 0, maxWidth: maxWidth, minHeight: height, maxHeight: height)
                .foregroundColor(foregroundColor(configuration))
                .background(backgroundColor(configuration))
                .cornerRadius(cornerRadius)
        }

        func foregroundColor(_ configuration: PrimaryButtonStyle.Configuration) -> Color {
            let baseColor = isEnabled ? Color.white : disabledForegroundColor
            return baseColor.opacity(configuration.isPressed ? 0.75 : 1)
        }

        func backgroundColor(_ configuration: PrimaryButtonStyle.Configuration) -> Color {
            guard isEnabled else { return disabledBackgroundColor }
            return Color.accentColor.opacity(configuration.isPressed ? 0.8 : 1)
        }

        var disabledForegroundColor: Color {
            Color.white.opacity(0.85)
        }

        var disabledBackgroundColor: Color {
            Color.accentColor.opacity(0.45)
        }
    }
}

// MARK: - Previews

struct PrimaryButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryButtonStylePreview()
            .previewLayout(.fixed(width: 300, height: 100))
    }

    struct PrimaryButtonStylePreview: View {
        var body: some View {
            Group {
                Button("Default") {}
                    .buttonStyle(PrimaryButtonStyle())

                Button("Disabled") {}
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(true)

                Button("Small") {}
                    .buttonStyle(PrimaryButtonStyle(size: .small))

                Button("Small") {}
                    .buttonStyle(PrimaryButtonStyle(size: .small))
                    .disabled(true)
            }
            .padding()
            .background(Color.aBackground)
        }
    }
}
