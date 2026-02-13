//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

#if os(macOS)
extension AddTimeRecordView {
    /// Builds the macOS-specific add-time-record layout.
    ///
    /// - Parameter viewModel: The state and logic container for the form.
    /// - Returns: A macOS-optimized content layout.
    @ViewBuilder
    func macContent(viewModel: AddTimeRecordViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingM) {
                orderSearchSection(viewModel: viewModel)

                HStack(alignment: .bottom, spacing: .spacingS) {
                    dateField(viewModel: viewModel)
                    durationField(viewModel: viewModel)
                    activityField(viewModel: viewModel)
                    startTimeField(viewModel: viewModel)
                    endTimeField(viewModel: viewModel)
                    clearButton(viewModel: viewModel)
                        .padding(.bottom, 6)
                }

                descriptionSection(viewModel: viewModel)
                clientSection(viewModel: viewModel)
            }
            .padding(.spacingM)
        }
    }
}
#endif
