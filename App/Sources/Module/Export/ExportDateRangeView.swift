//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Displays the date range selection for exporting blood pressure measurements.
///
/// This view allows users to select a start and end date for the export period,
/// view the count of measurements in that range, and proceed to the preview screen.
@MainActor
struct ExportDateRangeView: View {
    /// The view model managing export date range state.
    @State private var viewModel: ExportDateRangeViewModel

    /// The optional export format preselection for the preview step.
    private let preferredFormat: ExportFormat?

    /// The managed object context used for fetching measurements.
    @Environment(\.managedObjectContext) private var viewContext

    /// Controls navigation to the preview view.
    @State private var showPreview = false

    #if os(iOS)
    /// The horizontal size class used for wide-layout decisions on iOS.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// The vertical size class used for wide-layout decisions on iOS.
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    /// Creates an export date range view.
    ///
    /// - Parameters:
    ///   - context: The Core Data managed object context.
    ///   - preferredFormat: The optional export format preselection.
    init(context: NSManagedObjectContext, preferredFormat: ExportFormat? = nil) {
        _viewModel = State(initialValue: ExportDateRangeViewModel(context: context))
        self.preferredFormat = preferredFormat
    }

    /// The body of the export date range view.
    var body: some View {
        GeometryReader { proxy in
            if isWideLayout(proxy.size) {
                wideContent
            } else {
                portraitContent
            }
        }
        .background(Color.aBackground)
        .navigationTitle(L10n.generalMoreExportTitle)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .navigationDestination(isPresented: $showPreview) {
                ExportPreviewView(
                    startDate: viewModel.startDate,
                    endDate: viewModel.endDate,
                    context: viewContext,
                    preferredFormat: preferredFormat
                )
            }
            .onChange(of: viewModel.startDate) { _, _ in
                viewModel.updateMeasurementCount()
            }
            .onChange(of: viewModel.endDate) { _, _ in
                viewModel.updateMeasurementCount()
            }
            .onAppear {
                viewModel.updateMeasurementCount()
            }
    }
}

private extension ExportDateRangeView {
    /// The portrait-oriented date-range layout.
    var portraitContent: some View {
        VStack(spacing: 0) {
            List {
                dateRangeSection
                measurementCountSection
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .scrollContentBackground(.hidden)

            exportButton
                .padding(.horizontal, .spacingM)
                .padding(.top, .spacingS)
                .padding(.bottom, .spacingM)
        }
    }

    /// The wide two-column layout for landscape and desktop.
    var wideContent: some View {
        ScrollView {
            HStack(alignment: .top, spacing: .spacingM) {
                wideCard(title: L10n.exportDateRangeTitle) {
                    DatePicker(
                        L10n.exportDateRangeFrom,
                        selection: $viewModel.startDate,
                        displayedComponents: [.date]
                    )
                    .accessibilityLabel(L10n.accessibilityExportStartDate)

                    DatePicker(
                        L10n.exportDateRangeTo,
                        selection: $viewModel.endDate,
                        displayedComponents: [.date]
                    )
                    .accessibilityLabel(L10n.accessibilityExportEndDate)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(spacing: .spacingM) {
                    Text(L10n.generalMoreExportTitle)
                        .textStyle(.title3)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: .spacingS) {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundStyle(Color.accentColor)
                            .accessibilityHidden(true)

                        Text("17 Datensätze gefunden")
                            .textStyle(.body1)
                            .foregroundStyle(Color.aPrimary.opacity(0.9))

                        Spacer(minLength: 0)
                    }
                    .padding(.spacingM)
                    .background(Color.aListBackground)
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius))

                    exportButton
                }
                .frame(width: 360, alignment: .topLeading)
            }
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingM)
            .padding(.bottom, .spacingM)
        }
    }

    /// The list section containing date-range pickers.
    var dateRangeSection: some View {
        Section {
            DatePicker(
                L10n.exportDateRangeFrom,
                selection: $viewModel.startDate,
                displayedComponents: [.date]
            )
            .accessibilityLabel(L10n.accessibilityExportStartDate)

            DatePicker(
                L10n.exportDateRangeTo,
                selection: $viewModel.endDate,
                displayedComponents: [.date]
            )
            .accessibilityLabel(L10n.accessibilityExportEndDate)
        } header: {
            Text(L10n.exportDateRangeTitle)
                .textStyle(.title3)
                .accessibilityAddTraits(.isHeader)
        }
        .listRowBackground(Color.aListBackground)
    }

    /// The list section containing the measurement count card.
    var measurementCountSection: some View {
        Section {
            HStack(spacing: .spacingS) {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                Text("17 Datensätze gefunden")
                    .textStyle(.body1)
                    .foregroundStyle(Color.aPrimary.opacity(0.9))

                Spacer(minLength: 0)
            }
            .padding(.spacingM)
            .background(Color.aListBackground)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius))
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: .spacingS, leading: 0, bottom: .spacingS, trailing: 0))
    }

    /// The export action button.
    var exportButton: some View {
        Button {
            showPreview = true
        } label: {
            HStack {
                Spacer()
                Text(L10n.exportPreviewExportButton)
                    .textStyle(.button1)
                    .fontWeight(.medium)
                Spacer()
            }
            .frame(minHeight: 48)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.measurementCount == 0)
        .accessibilityLabel(L10n.exportPreviewExportButton)
    }

    /// Creates one wide-layout card container.
    ///
    /// - Parameters:
    ///   - title: The card title.
    ///   - content: The card content.
    /// - Returns: A styled card.
    func wideCard(
        title: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Text(title)
                .textStyle(.title3)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: .spacingS) {
                content()
            }
            .padding(.spacingM)
            .background(Color.aListBackground)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius))
        }
    }

    /// Determines whether the view should render the wide layout.
    ///
    /// - Parameter size: The current viewport size.
    /// - Returns: `true` for wide landscape/desktop layouts.
    func isWideLayout(_ size: CGSize) -> Bool {
        #if os(macOS)
        return true
        #else
        _ = size
        return horizontalSizeClass == .regular || verticalSizeClass == .compact
        #endif
    }
}
