//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

#if os(iOS)
extension MoreMenuView {
    /// The iOS sheet content used to pick the app appearance mode.
    var appearanceSelectionSheet: some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            Text(L10n.generalMoreAppearanceTitle)
                .textStyle(.title3)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, .spacingS)
                .padding(.bottom, .spacingXXS)

            VStack(alignment: .leading, spacing: .spacingXS) {
                ForEach(MoreMenuViewModel.AppearanceOption.allCases) { option in
                    appearanceOptionRow(for: option)
                }
            }
        }
        .padding(.horizontal, .screenMargin)
        .padding(.top, .spacingS)
        .padding(.bottom, .spacingS)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.aBackground)
        .animation(.easeInOut(duration: 0.18), value: viewModel.selectedAppearanceOption)
    }

    /// Creates a modern selectable row for an appearance option.
    ///
    /// - Parameter option: The appearance option to render.
    /// - Returns: The styled option row.
    func appearanceOptionRow(for option: MoreMenuViewModel.AppearanceOption) -> some View {
        let isSelected = option == viewModel.selectedAppearanceOption

        return Button {
            viewModel.appearanceSelection = option.rawValue
            viewModel.showsAppearanceSheet = false
        } label: {
            HStack(spacing: .spacingS) {
                Image(systemName: option.symbolName)
                    .imageScale(.small)
                    .foregroundStyle(isSelected ? Color.aDanger : Color.aPrimary.opacity(0.7))
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(Color.aListBackground)
                    )
                    .accessibilityHidden(true)

                Text(option.localizedTitle)
                    .textStyle(.body1)
                    .foregroundStyle(Color.aPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.small)
                        .foregroundStyle(Color.aDanger)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, .spacingS)
            .padding(.vertical, .spacingXS)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadius)
                    .fill(Color.aListBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: .cornerRadius)
                            .stroke(
                                isSelected ? Color.aDanger : Color.aPrimary.opacity(0.08),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: .cornerRadius))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius))
        .accessibilityLabel(option.localizedTitle)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
#endif
