//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

public struct TertiaryButtonStyle: ButtonStyle {
    public enum Size {
        case `default`, small
    }

    public enum Mode {
        case `default`, caution
    }

    private let height: CGFloat
    private let cornerRadius: CGFloat = 8

    public init(mode _: Mode = .default, size: Size = .default) {
        switch size {
        case .default:
            height = 48
        case .small:
            height = 32
        }
    }

    public func makeBody(configuration: Self.Configuration) -> some View {
        TertiaryButton(
            configuration: configuration,
            height: height,
            cornerRadius: cornerRadius
        )
    }

    private struct TertiaryButton: View {
        @Environment(\.isEnabled) private var isEnabled
        let configuration: TertiaryButtonStyle.Configuration
        let height: CGFloat
        let cornerRadius: CGFloat

        var body: some View {
            configuration.label
                .textStyle(.button1)
                .fontWeight(.medium)
                .padding(.horizontal, .spacingM)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: height, maxHeight: height)
                .foregroundColor(foregroundColor(configuration))
                .background(backgroundColor(configuration))
                .cornerRadius(cornerRadius)
        }

        func foregroundColor(_ configuration: TertiaryButtonStyle.Configuration) -> Color {
            let baseColor = isEnabled ? Color.aPrimary : disabledForegroundColor
            return baseColor.opacity(configuration.isPressed ? 0.75 : 1)
        }

        func backgroundColor(_ configuration: TertiaryButtonStyle.Configuration) -> Color {
            guard isEnabled else { return disabledBackgroundColor }
            return Color.aBackground.opacity(configuration.isPressed ? 0.8 : 1)
        }

        var disabledForegroundColor: Color {
            Color.aPrimary.opacity(0.45)
        }

        var disabledBackgroundColor: Color {
            Color.aBackground.opacity(0.45)
        }
    }
}

// MARK: - Previews

struct TertiaryButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        TertiaryButtonStylePreview()
            .previewLayout(.fixed(width: 300, height: 100))
    }

    struct TertiaryButtonStylePreview: View {
        var body: some View {
            Group {
                Button("Default") {}
                    .buttonStyle(TertiaryButtonStyle())

                Button("Default") {}
                    .buttonStyle(TertiaryButtonStyle())

                Button("Disabled") {}
                    .buttonStyle(TertiaryButtonStyle())
                    .disabled(true)

                Button("Small") {}
                    .buttonStyle(TertiaryButtonStyle(size: .small))

                Button("Small") {}
                    .buttonStyle(TertiaryButtonStyle(size: .small))

                Button("Small") {}
                    .buttonStyle(TertiaryButtonStyle(size: .small))
                    .disabled(true)
            }
            .padding()
            .background(Color.aBackground)
        }
    }
}
