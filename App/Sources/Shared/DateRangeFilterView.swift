//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

/// Placeholder date-range filter view.
@MainActor
struct DateRangeFilterView: View {
    @Binding var selectedPreset: DateRangePreset
    @Binding var fromDate: Date
    @Binding var toDate: Date
    let onPresetSelected: (DateRangePreset) -> Void
    let onApply: () -> Void
    let onReset: () -> Void

    var body: some View {
        EmptyView()
    }
}
