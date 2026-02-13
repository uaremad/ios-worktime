//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import PDFGenerator
import SwiftUI

/// Displays one prepared export file and provides the final share action.
@MainActor
struct ExportPreparedView: View {
    /// The prepared export payload to preview and share.
    let item: PreparedExportItem

    /// Activity item state used for presenting the share sheet on iOS.
    @State var exportActivityItem: ExportActivityItem?

    /// Parsed CSV preview rows.
    @State private var csvPreviewRows: [[String]] = []

    /// Stores the latest file operation error text for alert presentation.
    @State var fileOperationErrorMessage = ""

    /// Controls presentation of the file operation error alert.
    @State var showsFileOperationErrorAlert = false

    #if os(iOS)
    /// The horizontal size class used for layout decisions on iOS.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// The vertical size class used for layout decisions on iOS.
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// The managed object context used for entitlement checks before PDF export.
    @Environment(\.managedObjectContext) var viewContext

    /// Controls presentation of the purchases sheet when PDF export is locked.
    @State var showsPurchasesSheet: Bool = false

    /// Indicates whether export sharing preparation is currently in progress.
    @State var isPreparingExportShare: Bool = false
    #endif

    /// The body of the prepared export view.
    var body: some View {
        GeometryReader { proxy in
            if isWideLayout(proxy.size) {
                platformWideContent
            } else {
                portraitContent
            }
        }
        .navigationTitle(item.format == .pdf ? L10n.exportFormatPdf : L10n.exportFormatCsv)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .background(Color.aBackground)
            .onAppear {
                loadCSVPreviewIfNeeded()
            }
            .alert(L10n.errorBackupExportTitle, isPresented: $showsFileOperationErrorAlert) {
                Button(L10n.generalOk, role: .cancel) {}
            } message: {
                Text(fileOperationErrorMessage)
            }
        #if os(iOS)
            .sheet(item: $exportActivityItem) { exportActivityItem in
                ActivityViewController(activityItems: [exportActivityItem.url])
            }
            .sheet(isPresented: $showsPurchasesSheet) {
                NavigationStack {
                    MoreMenuPurchasesView()
                }
            }
        #endif
    }

    /// The portrait-oriented prepared export layout.
    private var portraitContent: some View {
        VStack(spacing: .spacingM) {
            previewContent
                .padding(.horizontal, .spacingM)
                .padding(.top, .spacingM)

            exportActionArea
                .padding(.horizontal, .spacingM)
                .padding(.bottom, .spacingM)
        }
    }

    /// Renders either PDF preview or CSV text preview.
    @ViewBuilder
    var previewContent: some View {
        switch item.format {
        case .pdf:
            PDFViewer(
                url: item.url,
                showsHandle: false,
                contentHorizontalPadding: 0
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.aListBackground)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius))
        case .csv:
            Group {
                if csvPreviewRows.isEmpty {
                    Text("Kein Daten gefunden")
                        .textStyle(.body2)
                        .foregroundStyle(Color.aPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.spacingM)
                } else {
                    ScrollView([.horizontal, .vertical]) {
                        ExportPreparedCSVPreviewTable(rows: csvPreviewRows)
                            .padding(.spacingM)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.aListBackground)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius))
        }
    }

    /// Loads CSV preview text from the prepared file.
    ///
    /// The preview is capped to keep the screen responsive for large exports.
    private func loadCSVPreviewIfNeeded() {
        guard item.format == .csv else { return }
        guard let content = try? String(contentsOf: item.url, encoding: .utf8) else {
            csvPreviewRows = []
            return
        }
        let cappedContent = String(content.prefix(40000))
        csvPreviewRows = ExportPreparedCSVParser.parseRows(from: cappedContent)
    }

    /// Determines whether the view should use a wide layout.
    ///
    /// - Parameter size: The current viewport size.
    /// - Returns: `true` when side-by-side layout is preferable.
    private func isWideLayout(_ size: CGSize) -> Bool {
        #if os(macOS)
        return true
        #else
        _ = size
        return horizontalSizeClass == .regular || verticalSizeClass == .compact
        #endif
    }
}

/// Renders a tabular CSV preview for prepared exports.
private struct ExportPreparedCSVPreviewTable: View {
    /// The parsed CSV rows including header row.
    let rows: [[String]]

    /// The body of the CSV preview table.
    var body: some View {
        let headerRow = rows.first ?? []
        let dataRows = Array(rows.dropFirst())
        let columnCount = max(
            headerRow.count,
            dataRows.map(\.count).max() ?? 0
        )

        return VStack(spacing: 0) {
            tableRow(
                headerRow,
                columnCount: columnCount,
                isHeader: true,
                isEvenRow: false
            )

            ForEach(Array(dataRows.enumerated()), id: \.offset) { index, row in
                tableRow(
                    row,
                    columnCount: columnCount,
                    isHeader: false,
                    isEvenRow: index.isMultiple(of: 2)
                )
            }
        }
        .background(Color.aBackground)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius))
    }

    /// Creates one table row for CSV preview rendering.
    ///
    /// - Parameters:
    ///   - values: The row values for each column.
    ///   - columnCount: The maximum number of columns.
    ///   - isHeader: Indicates whether this row is the header row.
    ///   - isEvenRow: Indicates whether this is an even data row.
    /// - Returns: A styled row view.
    private func tableRow(
        _ values: [String],
        columnCount: Int,
        isHeader: Bool,
        isEvenRow: Bool
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(0 ..< columnCount, id: \.self) { index in
                let text = index < values.count ? values[index] : ""
                csvCell(
                    text: text,
                    isHeader: isHeader,
                    isEvenRow: isEvenRow,
                    isFirstColumn: index == 0
                )
            }
        }
    }

    /// Creates one CSV preview table cell.
    ///
    /// - Parameters:
    ///   - text: The rendered text.
    ///   - isHeader: Indicates whether the cell belongs to the header row.
    ///   - isEvenRow: Indicates whether the row is even.
    ///   - isFirstColumn: Indicates whether the cell belongs to the first column.
    /// - Returns: A styled cell view.
    private func csvCell(
        text: String,
        isHeader: Bool,
        isEvenRow: Bool,
        isFirstColumn: Bool
    ) -> some View {
        Text(text)
            .textStyle(isHeader ? .body2 : .body3)
            .foregroundStyle(Color.aPrimary)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(width: isFirstColumn ? 210 : 110, alignment: .leading)
            .frame(minHeight: isHeader ? 34 : 30, alignment: .leading)
            .padding(.horizontal, .spacingXS)
            .background(cellBackground(isHeader: isHeader, isEvenRow: isEvenRow))
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.aPrimary.opacity(0.25), lineWidth: 0.5)
            )
    }

    /// Resolves the cell background for one row state.
    ///
    /// - Parameters:
    ///   - isHeader: Indicates whether the cell is in the header row.
    ///   - isEvenRow: Indicates whether the data row index is even.
    /// - Returns: The background color.
    private func cellBackground(isHeader: Bool, isEvenRow: Bool) -> Color {
        if isHeader {
            return Color.aColumnOdd.opacity(0.5)
        }
        return isEvenRow ? Color.aColumnEven.opacity(0.32) : Color.aBackground
    }
}

/// Parses CSV content for export preview rendering.
private enum ExportPreparedCSVParser {
    /// Parses CSV content with semicolon separator into rows.
    ///
    /// - Parameter content: The raw CSV text content.
    /// - Returns: Parsed rows and columns.
    static func parseRows(from content: String) -> [[String]] {
        let lines = content
            .components(separatedBy: .newlines)
            .filter { $0.isEmpty == false }

        return lines.map(parseLine)
    }

    /// Parses one semicolon-separated CSV line while respecting quoted fields.
    ///
    /// - Parameter line: One raw CSV line.
    /// - Returns: Parsed cell values.
    private static func parseLine(_ line: String) -> [String] {
        var cells: [String] = []
        var currentCell = ""
        var isInsideQuotes = false

        let characters = Array(line)
        var index = 0
        while index < characters.count {
            let character = characters[index]

            if character == "\"" {
                let nextIndex = index + 1
                if isInsideQuotes, nextIndex < characters.count, characters[nextIndex] == "\"" {
                    currentCell.append("\"")
                    index += 2
                    continue
                }
                isInsideQuotes.toggle()
                index += 1
                continue
            }

            if character == ";", isInsideQuotes == false {
                cells.append(currentCell)
                currentCell = ""
                index += 1
                continue
            }

            currentCell.append(character)
            index += 1
        }

        cells.append(currentCell)
        return cells
    }
}
