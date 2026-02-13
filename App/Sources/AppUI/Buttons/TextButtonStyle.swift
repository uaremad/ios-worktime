//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

public struct TextButtonStyle: ButtonStyle {
    public enum IconPosition {
        case left, right
    }

    private let iconPosition: IconPosition
    private let fixedForegroundColor: Color?

    /// Creates a text-only button style with an optional fixed foreground color.
    ///
    /// - Parameters:
    ///   - iconPosition: The icon placement within the label.
    ///   - foregroundColor: An optional fixed foreground color. When `nil`, the style uses
    ///     the default enabled/disabled dynamic colors.
    public init(iconPosition: IconPosition = .right, foregroundColor: Color? = nil) {
        self.iconPosition = iconPosition
        fixedForegroundColor = foregroundColor
    }

    public func makeBody(configuration: Self.Configuration) -> some View {
        TextButton(
            configuration: configuration,
            iconPosition: iconPosition,
            fixedForegroundColor: fixedForegroundColor
        )
    }

    private struct TextButton: View {
        @Environment(\.colorScheme) private var colorScheme: ColorScheme
        @Environment(\.isEnabled) var isEnabled
        let configuration: TextButtonStyle.Configuration
        let iconPosition: IconPosition
        let fixedForegroundColor: Color?

        var body: some View {
            configuration.label
                .labelStyle(labelStyle)
                .textStyle(.body1)
                .frame(minWidth: 0, maxWidth: nil, minHeight: .height, maxHeight: .height)
                .foregroundColor(foregroundColor(configuration))
                .background(Color.clearTappable)
                .cornerRadius(.height / 2)
        }

        func foregroundColor(_ configuration: TextButtonStyle.Configuration) -> Color {
            let baseColor: Color = if let fixedForegroundColor {
                isEnabled ? fixedForegroundColor : .secondary
            } else {
                isEnabled ? .primary : .secondary
            }

            if colorScheme == .dark {
                return baseColor.opacity(configuration.isPressed ? 0.5 : 1)
            }
            return baseColor.opacity(configuration.isPressed ? 0.5 : 1)
        }

        var labelStyle: AnyLabelStyle {
            switch iconPosition {
            case .left: DefaultLabelStyle().asAnyLabelStyle
            case .right: RightIconLabelStyle().asAnyLabelStyle
            }
        }
    }
}

private extension CGFloat {
    static let fontSize: Self = 16
    static let height: Self = 32
}

private extension Color {
    static let clearTappable = Color.white.opacity(0.0001)
}

private struct AnyLabelStyle: LabelStyle {
    let makeBody: (Self.Configuration) -> AnyView

    func makeBody(configuration: Self.Configuration) -> some View {
        makeBody(configuration)
    }
}

private extension LabelStyle {
    var asAnyLabelStyle: AnyLabelStyle {
        .init { AnyView(self.makeBody(configuration: $0)) }
    }
}

private struct RightIconLabelStyle: LabelStyle {
    func makeBody(configuration: LabelStyleConfiguration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

// MARK: - Previews

struct TextButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Button("Default") {}
                .buttonStyle(TextButtonStyle())

            Button("Disabled") {}
                .buttonStyle(TextButtonStyle())
                .disabled(true)
        }
        .previewLayout(.fixed(width: 300, height: 100))
    }
}
