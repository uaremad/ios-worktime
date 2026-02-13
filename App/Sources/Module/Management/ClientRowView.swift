//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

/// Row view for displaying a client in a list.
struct ClientRowView: View {
    let client: Client

    var body: some View {
        VStack(alignment: .leading) {
            Text(client.name ?? "")
                .textStyle(.body1)
            if let externalRef = client.external_ref, !externalRef.isEmpty {
                Text(externalRef)
                    .textStyle(.body3)
                    .foregroundColor(.secondary)
            }
            HStack {
                Text((client.is_active?.boolValue ?? true) ? L10n.generalActive : L10n.generalInactive)
                    .textStyle(.body3)
                    .foregroundColor((client.is_active?.boolValue ?? true) ? .green : .red)
                Spacer()
            }
        }
        .accessibilityLabel("\(client.name ?? ""), \(client.external_ref ?? ""), " +
            "\((client.is_active?.boolValue ?? true) ? L10n.generalActive : L10n.generalInactive)")
    }
}
