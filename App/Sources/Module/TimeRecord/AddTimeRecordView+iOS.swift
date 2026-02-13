//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

#if os(iOS) && !targetEnvironment(macCatalyst)
extension AddTimeRecordView {
    /// Builds the iOS-specific add-time-record layout.
    ///
    /// - Parameter viewModel: The state and logic container for the form.
    /// - Returns: An iOS-optimized content layout.
    @ViewBuilder
    func iOSContent(viewModel: AddTimeRecordViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingM) {
                orderSearchSection(viewModel: viewModel)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: .spacingS),
                        GridItem(.flexible(), spacing: .spacingS)
                    ],
                    alignment: .leading,
                    spacing: .spacingS
                ) {
                    dateField(viewModel: viewModel)
                    durationField(viewModel: viewModel)
                    activityField(viewModel: viewModel)
                    startTimeField(viewModel: viewModel)
                    endTimeField(viewModel: viewModel)
                }

                HStack {
                    Spacer()
                    clearButton(viewModel: viewModel)
                }

                descriptionSection(viewModel: viewModel)
                clientSection(viewModel: viewModel)
            }
            .padding(.spacingM)
        }
    }
}
#endif
