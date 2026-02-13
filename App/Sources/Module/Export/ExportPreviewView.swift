//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Displays export options and preview before exporting measurements.
///
/// This view allows users to select the export format (CSV or PDF),
/// configure export options, and preview the data before exporting.
@MainActor
struct ExportPreviewView: View {
    /// The view model managing export preview state.
    @State private var viewModel: ExportPreviewViewModel

    /// The managed object context used for fetching measurements.
    @Environment(\.managedObjectContext) private var viewContext

    /// The effective UI locale used for export localization.
    @Environment(\.locale) private var locale

    #if os(iOS)
    /// The horizontal size class used for layout decisions on iOS.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// The vertical size class used for layout decisions on iOS.
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    /// Creates an export preview view.
    ///
    /// - Parameters:
    ///   - startDate: The start date for the export range.
    ///   - endDate: The end date for the export range.
    ///   - context: The Core Data managed object context.
    ///   - preferredFormat: The optional export format preselection.
    init(
        startDate: Date,
        endDate: Date,
        context: NSManagedObjectContext,
        preferredFormat: ExportFormat? = nil
    ) {
        _viewModel = State(initialValue: ExportPreviewViewModel(
            startDate: startDate,
            endDate: endDate,
            context: context,
            initialFormat: preferredFormat ?? .csv
        ))
    }

    /// The body of the export preview view.
    var body: some View {
        GeometryReader { proxy in
            let usesWideLayout = isWideLayout(proxy.size)

            Group {
                if usesWideLayout {
                    wideContent
                } else {
                    portraitContent
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.aBackground)
        .navigationTitle(L10n.exportPreviewTitle)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .onAppear {
                viewModel.localeIdentifier = locale.identifier
                viewModel.loadMeasurements()
            }
            .onChange(of: locale) { _, newValue in
                viewModel.localeIdentifier = newValue.identifier
            }
            .navigationDestination(item: $viewModel.preparedExportItem) { item in
                ExportPreparedView(item: item)
            }
            .alert(L10n.errorBackupExportTitle, isPresented: $viewModel.showsPreparationErrorAlert) {
                Button(L10n.generalOk, role: .cancel) {}
            } message: {
                Text(viewModel.preparationErrorMessage)
            }
    }
}

private extension ExportPreviewView {
    /// The default portrait-oriented export preview layout.
    var portraitContent: some View {
        VStack(spacing: 0) {
            List {
                formatSection
                optionsSection
                summarySection
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif

            portraitActionButton
        }
    }

    /// The wide two-column export preview layout for landscape and desktop.
    var wideContent: some View {
        ScrollView {
            HStack(alignment: .top, spacing: .spacingM) {
                VStack(spacing: .spacingM) {
                    wideCard(title: L10n.exportPreviewFormatTitle) {
                        Picker(L10n.exportPreviewFormatTitle, selection: $viewModel.selectedFormat) {
                            ForEach(ExportFormat.allCases) { format in
                                Text(format.localizedTitle).tag(format)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel(L10n.exportPreviewFormatTitle)
                    }

                    wideCard(title: "") {
                        Toggle(L10n.exportPreviewIncludeComments, isOn: $viewModel.includeComments)
                            .textStyle(.body1)
                            .tint(Color.accentColor)
                            .accessibilityLabel(L10n.accessibilityExportIncludeComments)

                        if viewModel.selectedFormat == .pdf {
                            Toggle(L10n.exportPreviewBlackAndWhitePrint, isOn: $viewModel.useBlackAndWhitePrint)
                                .textStyle(.body1)
                                .tint(Color.accentColor)
                                .accessibilityLabel(L10n.accessibilityExportBlackAndWhitePrint)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: viewModel.selectedFormat)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(spacing: .spacingM) {
                    wideCard(title: L10n.exportPreviewSummaryTitle) {
                        VStack(alignment: .leading, spacing: .spacingXS) {
                            Text(viewModel.periodString)
                                .textStyle(.body1)
                                .foregroundStyle(Color.aPrimary.opacity(0.8))

                            Text(L10n.exportPreviewMeasurementCount(viewModel.measurements.count))
                                .textStyle(.body2)
                                .foregroundStyle(Color.aPrimary.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        viewModel.prepareExport()
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isExporting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Text(L10n.exportDateRangePreview)
                                    .textStyle(.button1)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                        }
                        .frame(minHeight: 48)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isExporting || viewModel.measurements.isEmpty)
                    .accessibilityLabel(L10n.exportDateRangePreview)
                }
                .frame(width: 320, alignment: .topLeading)
            }
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingM)
            .padding(.bottom, .spacingM)
        }
    }

    /// The export format selection section.
    var formatSection: some View {
        Section {
            Picker(L10n.exportPreviewFormatTitle, selection: $viewModel.selectedFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.localizedTitle).tag(format)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(L10n.exportPreviewFormatTitle)
        } header: {
            Text(L10n.exportPreviewFormatTitle)
                .textStyle(.title3)
                .accessibilityAddTraits(.isHeader)
        }
        .listRowBackground(Color.aListBackground)
    }

    /// The export options toggle section.
    var optionsSection: some View {
        Section {
            Toggle(L10n.exportPreviewIncludeComments, isOn: $viewModel.includeComments)
                .textStyle(.body1)
                .tint(Color.accentColor)
                .accessibilityLabel(L10n.accessibilityExportIncludeComments)

            if viewModel.selectedFormat == .pdf {
                Toggle(L10n.exportPreviewBlackAndWhitePrint, isOn: $viewModel.useBlackAndWhitePrint)
                    .textStyle(.body1)
                    .tint(Color.accentColor)
                    .accessibilityLabel(L10n.accessibilityExportBlackAndWhitePrint)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        } header: {
            Text(L10n.exportPreviewOptionsTitle)
                .textStyle(.title3)
                .accessibilityAddTraits(.isHeader)
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedFormat)
        .listRowBackground(Color.aListBackground)
    }

    /// The export summary section.
    var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(viewModel.periodString)
                    .textStyle(.body1)
                    .foregroundStyle(Color.aPrimary.opacity(0.8))

                Text(L10n.exportPreviewMeasurementCount(viewModel.measurements.count))
                    .textStyle(.body2)
                    .foregroundStyle(Color.aPrimary.opacity(0.6))
            }
        } header: {
            Text(L10n.exportPreviewSummaryTitle)
                .textStyle(.title3)
                .accessibilityAddTraits(.isHeader)
        }
        .listRowBackground(Color.aListBackground)
    }

    /// The portrait footer action button placed outside the list.
    var portraitActionButton: some View {
        Button {
            viewModel.prepareExport()
        } label: {
            HStack {
                Spacer()
                if viewModel.isExporting {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Text(L10n.exportDateRangePreview)
                        .textStyle(.button1)
                        .fontWeight(.medium)
                }
                Spacer()
            }
            .frame(minHeight: 48)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.isExporting || viewModel.measurements.isEmpty)
        .accessibilityLabel(L10n.exportDateRangePreview)
        .padding(.horizontal, .spacingM)
        .padding(.top, .spacingS)
        .padding(.bottom, .spacingM)
    }

    /// Creates one wide card with a title and custom content.
    ///
    /// - Parameters:
    ///   - title: The card title.
    ///   - content: The card body content.
    /// - Returns: A styled wide-layout card.
    func wideCard(
        title: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            if title.isEmpty == false {
                Text(title)
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)
            }

            VStack(alignment: .leading, spacing: .spacingS) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.spacingM)
            .background(Color.aListBackground)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius))
        }
    }

    /// Determines whether the export preview should use a two-column layout.
    ///
    /// - Parameter size: The current viewport size.
    /// - Returns: `true` when the view is wide enough for side-by-side columns.
    func isWideLayout(_ size: CGSize) -> Bool {
        #if os(macOS)
        return true
        #else
        _ = size
        return horizontalSizeClass == .regular || verticalSizeClass == .compact
        #endif
    }
}

/// Export format options.
enum ExportFormat: String, CaseIterable, Identifiable {
    case csv
    case pdf

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .csv:
            L10n.exportFormatCsv
        case .pdf:
            L10n.exportFormatPdf
        }
    }
}

#if os(iOS)
/// A UIViewControllerRepresentable for presenting a UIActivityViewController.
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
#endif
