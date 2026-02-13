//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
/// Displays macOS data tools for import and export workflows.
@MainActor
struct ExportView: View {
    /// The Core Data context passed to child flows.
    private let context: NSManagedObjectContext

    /// The selected start date for CSV export.
    @State private var csvStartDate: Date = Self.defaultStartDate

    /// The selected end date for CSV export.
    @State private var csvEndDate: Date = .init()

    /// Whether CSV export includes comments.
    @State private var csvIncludeComments = false

    /// Whether CSV export includes pulse pressure.
    @State private var csvIncludePulsePressure = false

    /// The selected start date for PDF export.
    @State private var pdfStartDate: Date = Self.defaultStartDate

    /// The selected end date for PDF export.
    @State private var pdfEndDate: Date = .init()

    /// Whether PDF export includes comments.
    @State private var pdfIncludeComments = false

    /// Whether PDF export includes pulse pressure.
    @State private var pdfIncludePulsePressure = false

    /// Whether PDF export uses black-and-white print mode.
    @State private var pdfUseBlackAndWhitePrint = false

    /// Controls presentation of the import file picker.
    @State private var showsImportFileImporter = false

    /// Indicates whether the file picker is currently opening.
    @State private var isOpeningImportFilePicker = false

    /// The selected import file used for direct navigation.
    @State private var selectedImportFile: MacSelectedImportFile?

    /// The selected export request used for direct export navigation.
    @State private var selectedExportRequest: MacExportRequest?

    /// Creates a macOS data management view.
    ///
    /// - Parameter context: The Core Data context used by import and export modules.
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// The body of the macOS data management view.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingM) {
                importSection
                csvExportSection
                pdfPrintSection
                peerSyncSection
            }
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingM)
            .padding(.bottom, .spacingL)
        }
        .background(Color.aBackground)
        .navigationTitle(L10n.generalTabData)
        .navigationDestination(item: $selectedImportFile) { importFile in
            ImportCSVPreparingView(
                context: context,
                fileURL: importFile.url
            )
        }
        .navigationDestination(item: $selectedExportRequest) { request in
            MacPreparedExportRouteView(
                context: context,
                request: request
            )
        }
        .fileImporter(
            isPresented: $showsImportFileImporter,
            allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
            isOpeningImportFilePicker = false
            switch result {
            case let .success(urls):
                if let url = urls.first {
                    selectedImportFile = MacSelectedImportFile(url: url)
                }
            case .failure:
                break
            }
        }
        .onChange(of: showsImportFileImporter) { _, isPresented in
            if isPresented == false {
                isOpeningImportFilePicker = false
            }
        }
    }

    /// The section offering CSV import.
    private var importSection: some View {
        dataCard(
            title: L10n.generalMoreImportTitle,
            systemImage: "square.and.arrow.down"
        ) {
            Text(L10n.generalImportIntroDescription)
                .textStyle(.body3)
                .foregroundStyle(Color.aPrimary.opacity(0.75))

            Button {
                isOpeningImportFilePicker = true
                showsImportFileImporter = true
            } label: {
                if isOpeningImportFilePicker {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, minHeight: 46)
                } else {
                    cardActionLabel(title: L10n.generalImportSelectFile)
                }
            }
            .accessibilityLabel(L10n.generalImportSelectFile)
            .buttonStyle(TertiaryButtonStyle())
            .disabled(isOpeningImportFilePicker)
        }
    }

    /// The section offering CSV export.
    private var csvExportSection: some View {
        dataCard(
            title: L10n.exportFormatCsv,
            systemImage: "tablecells"
        ) {
            HStack(alignment: .top, spacing: .spacingM) {
                HStack(spacing: .spacingS) {
                    styledDatePicker(
                        title: L10n.exportDateRangeFrom,
                        selection: $csvStartDate,
                        accessibilityLabel: L10n.accessibilityExportStartDate
                    )

                    styledDatePicker(
                        title: L10n.exportDateRangeTo,
                        selection: $csvEndDate,
                        accessibilityLabel: L10n.accessibilityExportEndDate
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: .spacingS) {
                    Toggle(L10n.exportPreviewIncludeComments, isOn: $csvIncludeComments)
                        .textStyle(.body1)
                        .tint(Color.accentColor)
                        .accessibilityLabel(L10n.accessibilityExportIncludeComments)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                selectedExportRequest = MacExportRequest(
                    format: .csv,
                    startDate: csvStartDate,
                    endDate: csvEndDate,
                    includeComments: csvIncludeComments,
                    includePulsePressure: csvIncludePulsePressure,
                    useBlackAndWhitePrint: false
                )
            } label: {
                cardActionLabel(title: L10n.exportDateRangePreview)
            }
            .accessibilityLabel(L10n.exportFormatCsv)
            .buttonStyle(TertiaryButtonStyle())
        }
        .onChange(of: csvStartDate) { _, newValue in
            if newValue > csvEndDate {
                csvEndDate = newValue
            }
        }
        .onChange(of: csvEndDate) { _, newValue in
            if newValue < csvStartDate {
                csvStartDate = newValue
            }
        }
    }

    /// The section offering PDF print export.
    private var pdfPrintSection: some View {
        dataCard(
            title: L10n.exportFormatPdf,
            systemImage: "printer"
        ) {
            HStack(alignment: .top, spacing: .spacingM) {
                HStack(spacing: .spacingS) {
                    styledDatePicker(
                        title: L10n.exportDateRangeFrom,
                        selection: $pdfStartDate,
                        accessibilityLabel: L10n.accessibilityExportStartDate
                    )

                    styledDatePicker(
                        title: L10n.exportDateRangeTo,
                        selection: $pdfEndDate,
                        accessibilityLabel: L10n.accessibilityExportEndDate
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: .spacingS) {
                    Toggle(L10n.exportPreviewIncludeComments, isOn: $pdfIncludeComments)
                        .textStyle(.body1)
                        .tint(Color.accentColor)
                        .accessibilityLabel(L10n.accessibilityExportIncludeComments)

                    Toggle(L10n.exportPreviewBlackAndWhitePrint, isOn: $pdfUseBlackAndWhitePrint)
                        .textStyle(.body1)
                        .tint(Color.accentColor)
                        .accessibilityLabel(L10n.accessibilityExportBlackAndWhitePrint)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                selectedExportRequest = MacExportRequest(
                    format: .pdf,
                    startDate: pdfStartDate,
                    endDate: pdfEndDate,
                    includeComments: pdfIncludeComments,
                    includePulsePressure: pdfIncludePulsePressure,
                    useBlackAndWhitePrint: pdfUseBlackAndWhitePrint
                )
            } label: {
                cardActionLabel(title: L10n.exportPdfCreateButton)
            }
            .accessibilityLabel(L10n.exportFormatPdf)
            .buttonStyle(TertiaryButtonStyle())
        }
        .onChange(of: pdfStartDate) { _, newValue in
            if newValue > pdfEndDate {
                pdfEndDate = newValue
            }
        }
        .onChange(of: pdfEndDate) { _, newValue in
            if newValue < pdfStartDate {
                pdfStartDate = newValue
            }
        }
    }

    /// The section offering local peer transfer to iOS.
    private var peerSyncSection: some View {
        LocalPeerSyncHostIntroView(presentationStyle: .embedded)
    }

    /// Creates one reusable action label for card buttons.
    ///
    /// - Parameter title: The localized action title.
    /// - Returns: A full-width button label.
    private func cardActionLabel(title: String) -> some View {
        HStack {
            Spacer()
            Text(title)
                .textStyle(.button1)
                .fontWeight(.medium)
            Spacer()
        }
        .frame(minHeight: 46)
    }

    /// Creates a styled date input field used by export sections.
    ///
    /// - Parameters:
    ///   - title: The localized field title.
    ///   - selection: The bound date value.
    ///   - accessibilityLabel: The accessibility label for VoiceOver.
    /// - Returns: A styled date picker field.
    private func styledDatePicker(
        title: String,
        selection: Binding<Date>,
        accessibilityLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            Text(title)
                .textStyle(.body3)
                .foregroundStyle(Color.aPrimary.opacity(0.8))

            DatePicker(
                "",
                selection: selection,
                displayedComponents: [.date]
            )
            .labelsHidden()
            .datePickerStyle(.field)
            .frame(alignment: .leading)
            .padding(.horizontal, .spacingXS)
            .padding(.vertical, .spacingXXXS)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadius)
                    .fill(Color.aBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadius)
                    .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius))
            .accessibilityLabel(accessibilityLabel)
        }
    }

    /// Wraps content into an overview-like card container.
    ///
    /// - Parameters:
    ///   - title: The card title.
    ///   - systemImage: The header SF Symbol.
    ///   - content: The content shown inside the card.
    /// - Returns: A styled card view.
    private func dataCard(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack(spacing: .spacingXS) {
                Image(systemName: systemImage)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                Text(title)
                    .textStyle(.title3)
                    .foregroundStyle(Color.aPrimary)
                    .accessibilityAddTraits(.isHeader)
            }

            VStack(alignment: .leading, spacing: .spacingS) {
                content()
            }
        }
        .padding(.spacingM)
        .background(
            RoundedRectangle(cornerRadius: .spacingM, style: .continuous)
                .fill(Color.aListBackground)
        )
    }

    /// The default export start date set to 30 days ago.
    private static var defaultStartDate: Date {
        Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    }
}

/// Stores one selected import file for direct navigation from macOS data view.
private struct MacSelectedImportFile: Identifiable, Hashable {
    /// Stable navigation identity.
    let id = UUID()

    /// The selected file URL.
    let url: URL
}

/// Stores one export request created from the macOS data view.
private struct MacExportRequest: Identifiable, Hashable {
    /// Stable navigation identity.
    let id = UUID()

    /// The selected export format.
    let format: ExportFormat

    /// The selected export start date.
    let startDate: Date

    /// The selected export end date.
    let endDate: Date

    /// Whether comments are included in the export.
    let includeComments: Bool

    /// Whether pulse pressure is included in the export.
    let includePulsePressure: Bool

    /// Whether black-and-white print mode is enabled.
    let useBlackAndWhitePrint: Bool
}

/// Prepares an export directly and routes to the prepared export view.
@MainActor
private struct MacPreparedExportRouteView: View {
    /// The request containing selected export options.
    let request: MacExportRequest

    /// The export preview view model reused for preparation logic.
    @State private var viewModel: ExportPreviewViewModel

    /// Indicates whether export preparation was already started.
    @State private var didStartPreparation = false

    /// The effective UI locale used for export localization.
    @Environment(\.locale) private var locale

    /// Creates a direct-export route view.
    ///
    /// - Parameters:
    ///   - context: The Core Data context used for loading and export.
    ///   - request: The selected export request.
    init(context: NSManagedObjectContext, request: MacExportRequest) {
        self.request = request
        _viewModel = State(initialValue: ExportPreviewViewModel(
            startDate: request.startDate,
            endDate: request.endDate,
            context: context,
            initialFormat: request.format
        ))
    }

    /// The body of the direct-export route view.
    var body: some View {
        Group {
            if let item = viewModel.preparedExportItem {
                ExportPreparedView(item: item)
            } else {
                VStack(spacing: .spacingM) {
                    ProgressView()
                        .progressViewStyle(.circular)

                    Text(L10n.exportDateRangePreview)
                        .textStyle(.body2)
                        .foregroundStyle(Color.aPrimary.opacity(0.75))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.aBackground)
            }
        }
        .alert(L10n.errorBackupExportTitle, isPresented: $viewModel.showsPreparationErrorAlert) {
            Button(L10n.generalOk, role: .cancel) {}
        } message: {
            Text(viewModel.preparationErrorMessage)
        }
        .onAppear {
            viewModel.localeIdentifier = locale.identifier
            prepareExportIfNeeded()
        }
        .onChange(of: locale) { _, newValue in
            viewModel.localeIdentifier = newValue.identifier
        }
    }

    /// Starts export preparation once using the selected request options.
    private func prepareExportIfNeeded() {
        guard didStartPreparation == false else { return }
        didStartPreparation = true

        viewModel.includeComments = request.includeComments
        viewModel.includePulsePressure = request.includePulsePressure
        viewModel.useBlackAndWhitePrint = request.useBlackAndWhitePrint
        viewModel.loadMeasurements()
        viewModel.prepareExport()
    }
}
#endif
