//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if os(macOS)
import AppKit
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

extension ExportPreparedView {
    /// Creates the macOS-specific wide layout.
    @ViewBuilder
    var platformWideContent: some View {
        if item.format == .csv {
            VStack(spacing: .spacingM) {
                previewContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                exportActionArea
            }
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingM)
            .padding(.bottom, .spacingM)
        } else {
            HStack(alignment: .top, spacing: .spacingM) {
                previewContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(alignment: .leading, spacing: .spacingM) {
                    VStack(alignment: .leading, spacing: .spacingXS) {
                        Text(L10n.exportPreviewSummaryTitle)
                            .textStyle(.title3)
                            .accessibilityAddTraits(.isHeader)

                        Text(item.url.lastPathComponent)
                            .textStyle(.body3)
                            .foregroundStyle(Color.aPrimary.opacity(0.75))
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.spacingM)
                    .background(Color.aListBackground)
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius))

                    exportActionArea
                }
                .frame(width: 320, alignment: .topLeading)
            }
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingM)
            .padding(.bottom, .spacingM)
        }
    }

    /// Creates the macOS-specific action area.
    @ViewBuilder
    var exportActionArea: some View {
        if item.format == .pdf {
            VStack(spacing: .spacingS) {
                Button {
                    savePreparedFileAs()
                } label: {
                    HStack {
                        Spacer()
                        Text(L10n.exportPreparedSaveButton)
                            .textStyle(.button1)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .frame(minHeight: 48)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel(L10n.exportPreparedSaveButton)

                Button {
                    printPDF()
                } label: {
                    HStack {
                        Spacer()
                        Text(L10n.exportPreparedPrintButton)
                            .textStyle(.button1)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .frame(minHeight: 48)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel(L10n.exportPreparedPrintButton)
            }
        } else {
            Button {
                savePreparedFileAs()
            } label: {
                HStack {
                    Spacer()
                    Text(L10n.exportPreparedSaveButton)
                        .textStyle(.button1)
                        .fontWeight(.medium)
                    Spacer()
                }
                .frame(minHeight: 48)
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityLabel(L10n.exportPreparedSaveButton)
        }
    }

    /// Presents a Save panel and copies the prepared export file to the selected location.
    func savePreparedFileAs() {
        do {
            try ExportPreparedMacFileActions.saveAs(
                sourceURL: item.url,
                format: item.format
            )
        } catch {
            fileOperationErrorMessage = error.localizedDescription
            showsFileOperationErrorAlert = true
        }
    }

    /// Opens the native macOS print dialog for the prepared PDF.
    func printPDF() {
        do {
            try ExportPreparedMacFileActions.printPDF(at: item.url)
        } catch {
            fileOperationErrorMessage = "Kein Daten gefunden"
            showsFileOperationErrorAlert = true
        }
    }
}

/// Performs file actions for prepared exports on macOS.
private enum ExportPreparedMacFileActions {
    /// Presents a Save panel and copies a prepared export file to the selected destination.
    ///
    /// - Parameters:
    ///   - sourceURL: The generated export file URL.
    ///   - format: The export format used to constrain file types.
    /// - Throws: Any file system error raised while replacing or copying.
    static func saveAs(sourceURL: URL, format: ExportFormat) throws {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = sourceURL.lastPathComponent
        savePanel.allowedContentTypes = [allowedContentType(for: format)]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false

        guard savePanel.runModal() == .OK, let destinationURL = savePanel.url else {
            return
        }

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
    }

    /// Opens the native print dialog for a prepared PDF file.
    ///
    /// - Parameter url: The PDF file URL.
    /// - Throws: `CocoaError(.fileReadCorruptFile)` when the PDF cannot be loaded.
    static func printPDF(at url: URL) throws {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let printInfo = NSPrintInfo.shared.copy() as? NSPrintInfo ?? NSPrintInfo()
        // DIN A4 in points (1/72 inch): 210 x 297 mm.
        printInfo.paperSize = NSSize(width: 595.28, height: 841.89)
        printInfo.topMargin = 18
        printInfo.bottomMargin = 18
        printInfo.leftMargin = 18
        printInfo.rightMargin = 18
        printInfo.horizontalPagination = .automatic
        printInfo.verticalPagination = .automatic
        printInfo.isHorizontallyCentered = true
        printInfo.isVerticallyCentered = true

        guard let printOperation = pdfDocument.printOperation(
            for: printInfo,
            scalingMode: .pageScaleToFit,
            autoRotate: true
        ) else {
            throw CocoaError(.fileReadUnknown)
        }

        printOperation.showsPrintPanel = true
        printOperation.showsProgressPanel = true
        printOperation.run()
    }

    /// Resolves the allowed content type for the selected prepared export format.
    ///
    /// - Parameter format: The prepared export format.
    /// - Returns: The matching UTType for save panel validation.
    private static func allowedContentType(for format: ExportFormat) -> UTType {
        switch format {
        case .pdf:
            .pdf
        case .csv:
            .commaSeparatedText
        }
    }
}
#endif
