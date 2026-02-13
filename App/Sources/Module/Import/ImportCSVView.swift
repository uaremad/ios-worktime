//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI
import UniformTypeIdentifiers

/// Presents the first CSV import step with file selection only.
@MainActor
struct ImportCSVView: View {
    /// The Core Data context passed to the preparation view.
    private let context: NSManagedObjectContext

    /// Controls presentation of the file importer.
    @State private var showsFileImporter = false

    /// Indicates whether the file picker is currently being opened.
    @State private var isOpeningFilePicker = false

    /// The selected import file used for navigation.
    @State private var selectedImportFile: SelectedImportFile?

    #if os(macOS)
    /// Indicates whether a drag-and-drop operation targets the import surface.
    @State private var isDropTargeted = false
    #endif

    /// Creates a CSV import view.
    ///
    /// - Parameter context: The Core Data context used for saving.
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// The body of the CSV import selection view.
    var body: some View {
        VStack(spacing: 0) {
            ContentUnavailableView {
                Label(L10n.generalMoreImportTitle, systemImage: "square.and.arrow.down")
            } description: {
                Text(L10n.generalImportIntroDescription)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingM)

            Button {
                isOpeningFilePicker = true
                showsFileImporter = true
            } label: {
                HStack {
                    Spacer()
                    if isOpeningFilePicker {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text(L10n.generalImportSelectFile)
                            .textStyle(.button1)
                            .fontWeight(.medium)
                    }
                    Spacer()
                }
                .frame(minHeight: 48)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isOpeningFilePicker)
            .accessibilityLabel(L10n.generalImportSelectFile)
            .accessibilityAddTraits(.isButton)
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingS)
            .padding(.bottom, .spacingM)
        }
        .background(Color.aBackground)
        .navigationTitle(L10n.generalMoreImportTitle)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        #if os(macOS)
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: .cornerRadius)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    .padding(.spacingM)
                    .allowsHitTesting(false)
            }
        }
        .onDrop(
            of: [UTType.fileURL.identifier],
            isTargeted: $isDropTargeted,
            perform: handleDroppedFiles
        )
        #endif
        .navigationDestination(item: $selectedImportFile) { importFile in
            ImportCSVPreparingView(
                context: context,
                fileURL: importFile.url
            )
        }
        .fileImporter(
            isPresented: $showsFileImporter,
            allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
            isOpeningFilePicker = false
            switch result {
            case let .success(urls):
                if let url = urls.first {
                    selectedImportFile = SelectedImportFile(url: url)
                }
            case .failure:
                break
            }
        }
        .onChange(of: showsFileImporter) { _, isPresented in
            if isPresented == false {
                isOpeningFilePicker = false
            }
        }
    }

    #if os(macOS)
    /// Handles dropped files and starts the import preparation flow.
    ///
    /// - Parameter providers: The dropped item providers.
    /// - Returns: `true` when a suitable file provider is accepted.
    private func handleDroppedFiles(_ providers: [NSItemProvider]) -> Bool {
        guard
            let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) })
        else {
            return false
        }

        provider.loadFileRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { url, _ in
            guard let sourceURL = url else {
                return
            }

            let ext = sourceURL.pathExtension.lowercased()
            guard ext == "csv" || ext == "txt" else {
                return
            }

            let tempDirectory = FileManager.default.temporaryDirectory
            let targetURL = tempDirectory.appendingPathComponent("\(UUID().uuidString)-\(sourceURL.lastPathComponent)")

            do {
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    try FileManager.default.removeItem(at: targetURL)
                }
                try FileManager.default.copyItem(at: sourceURL, to: targetURL)

                Task { @MainActor in
                    selectedImportFile = SelectedImportFile(url: targetURL)
                }
            } catch {
                return
            }
        }

        return true
    }
    #endif
}

/// Presents the second CSV import step with preparation and mapping controls.
@MainActor
struct ImportCSVPreparingView: View {
    /// The view model powering CSV parsing and mapping.
    @State private var viewModel: ImportCSVViewModel

    /// Dismiss action used to leave the preparing view.
    @Environment(\.dismiss) private var dismiss

    /// The selected CSV file URL.
    let fileURL: URL

    /// Indicates whether mapping should open automatically after preparation.
    let opensMappingOnAppear: Bool

    /// Indicates whether initial file preparation is running.
    @State private var isPreparingFile = true

    /// Prevents repeated preparation loads.
    @State private var didStartPreparation = false

    /// Controls navigation to the mapping detail view.
    @State private var showsMappingView = false

    /// Controls presentation of the import success sheet.
    @State private var showsImportSuccessSheet = false

    /// Stores the imported row count displayed in the success sheet.
    @State private var successImportCount = 0

    #if os(iOS)
    /// The horizontal size class used for wide-layout decisions on iOS.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// The vertical size class used for wide-layout decisions on iOS.
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    /// Creates the CSV preparation view.
    ///
    /// - Parameters:
    ///   - context: The Core Data context used for saving.
    ///   - fileURL: The selected CSV file URL.
    ///   - opensMappingOnAppear: Whether mapping should open automatically after file parsing.
    init(
        context: NSManagedObjectContext,
        fileURL: URL,
        opensMappingOnAppear: Bool = false
    ) {
        _viewModel = State(initialValue: ImportCSVViewModel(context: context))
        self.fileURL = fileURL
        self.opensMappingOnAppear = opensMappingOnAppear
    }

    /// The body of the CSV preparation view.
    var body: some View {
        Group {
            if isPreparingFile {
                VStack(spacing: .spacingM) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text(L10n.generalMoreImportTitle)
                        .textStyle(.body2)
                        .foregroundStyle(Color.aPrimary.opacity(0.75))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { proxy in
                    if isWideLayout(proxy.size), viewModel.hasParsedFile {
                        wideContent
                    } else {
                        portraitContent
                    }
                }
            }
        }
        .background(Color.aBackground)
        .navigationTitle(L10n.generalMoreImportTitle)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .navigationDestination(isPresented: $showsMappingView) {
                ImportCSVMappingView(viewModel: viewModel)
            }
            .onAppear {
                prepareFileIfNeeded()
            }
            .onChange(of: viewModel.delimiterSelection) { _, _ in
                viewModel.reparseFile()
            }
            .onChange(of: viewModel.hasHeaderRow) { _, _ in
                viewModel.reparseFile()
            }
            .sheet(
                isPresented: $showsImportSuccessSheet,
                onDismiss: {
                    completeImportFlow()
                },
                content: {
                    importSuccessSheet
                }
            )
    }

    /// The default portrait content for CSV preparation.
    private var portraitContent: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    Text(L10n.generalImportSelectedFile(viewModel.selectedFileName))
                        .textStyle(.body3)
                        .accessibilityLabel(L10n.generalImportSelectedFile(viewModel.selectedFileName))

                    if viewModel.rows.isEmpty == false {
                        VStack(alignment: .leading, spacing: .spacingXXS) {
                            ForEach(Array(viewModel.rows.prefix(3).enumerated()), id: \.offset) { _, row in
                                Text(csvPreviewLine(for: row))
                                    .textStyle(.body3)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                    }
                } header: {
                    Text(L10n.generalImportFileSection)
                        .textStyle(.title3)
                        .accessibilityAddTraits(.isHeader)
                }
                .listRowBackground(Color.aListBackground)

                if viewModel.hasParsedFile {
                    Section {
                        importableDataContent
                    } header: {
                        Text(L10n.generalImportDataSection)
                            .textStyle(.title3)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .listRowBackground(Color.aListBackground)
                } else if let errorText = importErrorText {
                    Section {
                        Text(errorText)
                            .textStyle(.body2)
                            .foregroundStyle(Color.aDanger)
                    }
                    .listRowBackground(Color.aListBackground)
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .scrollContentBackground(.hidden)

            if viewModel.hasParsedFile {
                importActionButton
            }
        }
    }

    /// The wide content showing file and importable data side by side.
    private var wideContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                wideCardsLayout
                    .padding(.horizontal, .spacingM)
                    .padding(.top, .spacingM)
                    .padding(.bottom, .spacingM)
            }

            importActionButton
        }
    }

    /// Creates the platform-specific card arrangement for wide layouts.
    private var wideCardsLayout: some View {
        Group {
            #if os(macOS)
            VStack(alignment: .leading, spacing: .spacingM) {
                wideFileCard
                wideImportableDataCard
            }
            #else
            HStack(alignment: .top, spacing: .spacingM) {
                wideFileCard
                wideImportableDataCard
            }
            #endif
        }
    }

    /// The wide-layout file information card.
    private var wideFileCard: some View {
        wideCard(title: L10n.generalImportFileSection) {
            Text(L10n.generalImportSelectedFile(viewModel.selectedFileName))
                .textStyle(.body3)
                .accessibilityLabel(L10n.generalImportSelectedFile(viewModel.selectedFileName))

            if viewModel.rows.isEmpty == false {
                VStack(alignment: .leading, spacing: .spacingXXS) {
                    ForEach(Array(viewModel.rows.prefix(3).enumerated()), id: \.offset) { _, row in
                        Text(csvPreviewLine(for: row))
                            .textStyle(.body3)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    /// The wide-layout importable-data card.
    private var wideImportableDataCard: some View {
        wideCard(title: L10n.generalImportDataSection) {
            importableDataContent
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    /// The shared importable data content block.
    private var importableDataContent: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack(spacing: .spacingS) {
                Image(systemName: "tray.full")
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                Text(L10n.generalImportRowCount(viewModel.importableRowCount))
                    .textStyle(.body1)
                    .foregroundStyle(Color.aPrimary.opacity(0.9))

                Spacer(minLength: 0)
            }

            Button {
                showsMappingView = true
            } label: {
                HStack(spacing: .spacingS) {
                    Text(L10n.generalImportMappingTitle)
                        .textStyle(.body1)
                        .foregroundStyle(Color.aPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.generalImportMappingTitle)

            if viewModel.hasRequiredMapping == false {
                Text("Fehler")
                    .textStyle(.body3)
                    .foregroundStyle(Color.aDanger)
            }

            if let errorText = importErrorText {
                Text(errorText)
                    .textStyle(.body3)
                    .foregroundStyle(Color.aDanger)
            }
        }
    }

    /// The shared footer action button.
    private var importActionButton: some View {
        Button {
            Task {
                await viewModel.performImport()
                if let importedCount = viewModel.importedCount, importedCount > 0 {
                    successImportCount = importedCount
                    showsImportSuccessSheet = true
                }
            }
        } label: {
            HStack {
                Spacer()
                if viewModel.isImporting {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Text(L10n.generalImportButton)
                        .textStyle(.button1)
                        .fontWeight(.medium)
                }
                Spacer()
            }
            .frame(minHeight: 48)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.isImporting || !viewModel.hasRequiredMapping)
        .accessibilityLabel(L10n.generalImportButton)
        .padding(.horizontal, .spacingM)
        .padding(.top, .spacingS)
        .padding(.bottom, .spacingM)
    }

    /// The modal sheet shown after a successful import.
    private var importSuccessSheet: some View {
        VStack(spacing: .spacingM) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 156, height: 156)
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            Text(L10n.generalImportResult(successImportCount))
                .textStyle(.title3)
                .multilineTextAlignment(.center)

            Button {
                showsImportSuccessSheet = false
            } label: {
                Text(L10n.generalOk)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityLabel(L10n.generalOk)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.spacingM)
        .background(Color.aBackground)
        #if os(iOS)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        #endif
    }
}

private extension ImportCSVPreparingView {
    /// Creates one wide-layout card with title and content.
    ///
    /// - Parameters:
    ///   - title: The card section title.
    ///   - content: The card body content.
    /// - Returns: A styled card view.
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.spacingM)
            .background(Color.aListBackground)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius))
        }
    }

    /// Determines whether the preparing view should use a wide layout.
    ///
    /// - Parameter size: The current viewport size.
    /// - Returns: `true` for iPad/mac landscape-like layouts.
    func isWideLayout(_ size: CGSize) -> Bool {
        #if os(macOS)
        return true
        #else
        _ = size
        return horizontalSizeClass == .regular || verticalSizeClass == .compact
        #endif
    }

    /// Starts asynchronous preparation for the selected file once.
    func prepareFileIfNeeded() {
        guard didStartPreparation == false else { return }
        didStartPreparation = true

        Task {
            await viewModel.loadFile(from: fileURL)
            isPreparingFile = false
            if opensMappingOnAppear, viewModel.hasParsedFile {
                showsMappingView = true
            }
        }
    }

    /// Completes the import flow and returns to the import selection screen.
    func completeImportFlow() {
        dismiss()
    }

    /// Converts one CSV row into a compact preview line.
    ///
    /// - Parameter row: The CSV row values.
    /// - Returns: A single-line preview string.
    func csvPreviewLine(for row: [String]) -> String {
        row
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: " | ")
    }

    /// The localized import error text.
    var importErrorText: String? {
        switch viewModel.error {
        case .readFailed:
            L10n.generalImportErrorRead
        case .noRows:
            L10n.generalImportErrorNoRows
        case .missingMapping:
            "Fehler beim Erstellen einer Zuordunung. Bitte überprüfen die Struktur Ihrer Datei."
        case .saveFailed:
            L10n.generalImportErrorSave
        case .none:
            nil
        }
    }
}

/// Displays advanced CSV mapping options on a dedicated screen.
@MainActor
struct ImportCSVMappingView: View {
    /// The shared import view model.
    let viewModel: ImportCSVViewModel

    /// Indicates whether mapping content is still preparing.
    @State private var isPreparingContent = true

    /// Prevents repeated preparation when the view reappears.
    @State private var didStartPreparing = false

    /// The body of the mapping detail view.
    var body: some View {
        @Bindable var bindableViewModel = viewModel

        Group {
            if isPreparingContent {
                VStack(spacing: .spacingM) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text(L10n.generalImportMappingTitle)
                        .textStyle(.body2)
                        .foregroundStyle(Color.aPrimary.opacity(0.75))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        Text(L10n.generalImportSelectedFile(viewModel.selectedFileName))
                            .textStyle(.body3)
                            .accessibilityLabel(L10n.generalImportSelectedFile(viewModel.selectedFileName))

                        if viewModel.rows.isEmpty == false {
                            VStack(alignment: .leading, spacing: .spacingXXS) {
                                ForEach(Array(viewModel.rows.prefix(3).enumerated()), id: \.offset) { _, row in
                                    Text(csvPreviewLine(for: row))
                                        .textStyle(.body3)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                        }
                    } header: {
                        Text(L10n.generalImportFileSection)
                            .textStyle(.title3)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .listRowBackground(Color.aListBackground)

                    Section {
                        Picker(L10n.generalImportDelimiterTitle, selection: $bindableViewModel.delimiterSelection) {
                            Text(L10n.generalImportDelimiterAuto).tag(ImportCSVViewModel.CSVDelimiter.auto)
                            Text(L10n.generalImportDelimiterSemicolon).tag(ImportCSVViewModel.CSVDelimiter.semicolon)
                            Text(L10n.generalImportDelimiterComma).tag(ImportCSVViewModel.CSVDelimiter.comma)
                            Text(L10n.generalImportDelimiterTab).tag(ImportCSVViewModel.CSVDelimiter.tab)
                        }
                        .pickerStyle(.segmented)
                        .tint(Color.accentColor)
                        .accessibilityLabel(L10n.generalImportDelimiterTitle)

                        Toggle(L10n.generalImportHeaderRow, isOn: $bindableViewModel.hasHeaderRow)
                            .textStyle(.body1)
                            .tint(Color.accentColor)
                            .accessibilityLabel(L10n.generalImportHeaderRow)
                    } header: {
                        Text(L10n.generalImportDelimiterTitle)
                            .textStyle(.title3)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .listRowBackground(Color.aListBackground)

                    Section {
                        mappingRow(
                            title: L10n.generalImportFieldDate,
                            selection: $bindableViewModel.dateColumnSelection
                        )
                        mappingRow(
                            title: L10n.exportDateRangeFrom,
                            selection: $bindableViewModel.startColumnSelection
                        )
                        mappingRow(
                            title: L10n.exportDateRangeTo,
                            selection: $bindableViewModel.endColumnSelection
                        )
                    } header: {
                        Text(L10n.generalImportMappingTitle)
                            .textStyle(.title3)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .listRowBackground(Color.aListBackground)
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.inset)
                #endif
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color.aBackground)
        .navigationTitle(L10n.generalImportMappingTitle)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .onAppear {
                prepareMappingIfNeeded()
            }
    }

    /// Starts mapping view preparation once after navigation.
    private func prepareMappingIfNeeded() {
        guard didStartPreparing == false else { return }
        didStartPreparing = true

        Task {
            await Task.yield()
            viewModel.reparseFile()
            isPreparingContent = false
        }
    }

    /// Builds one mapping row with field label and picker.
    ///
    /// - Parameters:
    ///   - title: The localized field title.
    ///   - selection: The selected column index.
    /// - Returns: The row view.
    private func mappingRow(title: String, selection: Binding<Int>) -> some View {
        HStack(spacing: .spacingS) {
            VStack(alignment: .leading, spacing: .spacingXXXXS) {
                Text(title)
                    .textStyle(.body1)
                    .lineLimit(1)

                Text(sampleValueText(for: selection.wrappedValue))
                    .textStyle(.body3)
                    .foregroundStyle(Color.aPrimary.opacity(0.6))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Picker("", selection: selection) {
                ForEach(columnOptions) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(minWidth: 220, alignment: .trailing)
            .accessibilityLabel(title)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    /// Returns one sample value text for the selected column from the first data row.
    ///
    /// - Parameter columnIndex: The selected column index.
    /// - Returns: The preview value or a placeholder when unavailable.
    private func sampleValueText(for columnIndex: Int) -> String {
        guard columnIndex >= 0 else {
            return "-"
        }

        let dataRowIndex = viewModel.hasHeaderRow ? 1 : 0
        guard
            viewModel.rows.indices.contains(dataRowIndex),
            viewModel.rows[dataRowIndex].indices.contains(columnIndex)
        else {
            return "-"
        }

        let value = viewModel.rows[dataRowIndex][columnIndex]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return value.isEmpty ? "-" : value
    }

    /// Provides the mapping options for the current file.
    private var columnOptions: [ColumnOption] {
        var options: [ColumnOption] = [
            ColumnOption(id: -1, title: L10n.generalImportColumnNone)
        ]
        for index in 0 ..< viewModel.columnCount {
            options.append(
                ColumnOption(
                    id: index,
                    title: columnOptionTitle(for: index)
                )
            )
        }
        return options
    }

    /// Builds one user-friendly column option title for mapping menus.
    ///
    /// - Parameter index: The zero-based column index.
    /// - Returns: Header-based title when available, otherwise column number.
    private func columnOptionTitle(for index: Int) -> String {
        let fallbackTitle = L10n.generalImportColumnNumber(index + 1)
        guard
            viewModel.hasHeaderRow,
            let headerRow = viewModel.rows.first,
            headerRow.indices.contains(index)
        else {
            return fallbackTitle
        }

        let headerTitle = headerRow[index].trimmingCharacters(in: .whitespacesAndNewlines)
        guard headerTitle.isEmpty == false else {
            return fallbackTitle
        }

        return "\(headerTitle) (\(fallbackTitle))"
    }

    /// Converts one CSV row into a compact preview line.
    ///
    /// - Parameter row: The CSV row values.
    /// - Returns: A single-line preview string.
    private func csvPreviewLine(for row: [String]) -> String {
        row
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: " | ")
    }
}

/// Stores one selected import file for navigation.
private struct SelectedImportFile: Identifiable, Hashable {
    /// Stable navigation identity.
    let id = UUID()

    /// The selected file URL.
    let url: URL
}

/// Represents a column option in the mapping picker.
private struct ColumnOption: Identifiable {
    /// The column identifier.
    let id: Int

    /// The localized title for the column.
    let title: String
}
