//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

/// Renders a reusable empty-state block for management flows.
@MainActor
struct ManagementEmptyStateView: View {
    /// The title text shown in the empty-state.
    let title: String

    /// The descriptive helper text.
    let message: String

    /// The primary action title.
    let actionTitle: String

    /// The action executed when users tap the primary button.
    let action: () -> Void

    /// Renders the empty-state body.
    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "person.3")
        } description: {
            Text(message)
                .textStyle(.body3)
        } actions: {
            Button(actionTitle, action: action)
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityAddTraits(.isButton)
        }
    }
}
