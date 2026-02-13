//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

/// A reusable toast view for displaying saved measurement feedback.
///
/// This component renders a compact gradient card with a colored systolic badge,
/// a result title, a timestamp line, and an action button.
@MainActor
struct SaveResultToastView: View {
    /// The systolic value shown in the leading badge.
    let systolicValue: Int

    /// The localized result title.
    let resultTitle: String

    /// The localized date-time line shown below the title.
    let timestampText: String

    /// The classification color used for the badge.
    let resultColor: Color

    /// The localized action button title.
    let actionTitle: String

    /// Callback invoked when the action button is tapped.
    let onAction: () -> Void

    /// The body of the save result toast.
    var body: some View {
        HStack(alignment: .top, spacing: .spacingM) {
            Text("\(systolicValue)")
                .textStyle(.body1)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: .cornerRadius)
                        .fill(resultColor)
                )

            VStack(alignment: .leading, spacing: .spacingXXS) {
                Text(resultTitle)
                    .textStyle(.body1)
                Text(timestampText)
                    .textStyle(.body2)
                    .foregroundStyle(Color.aPrimary.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(actionTitle, action: onAction)
                .textStyle(.body1)
                .accessibilityLabel(actionTitle)
        }
        .padding(.spacingM)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.aListBackground.opacity(0.98),
                            Color.aBackground.opacity(0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadius)
                .stroke(Color.aPrimary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 4)
    }
}
