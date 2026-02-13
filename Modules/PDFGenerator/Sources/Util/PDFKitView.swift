//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import PDFKit
import SwiftUI

/// Displays a PDF document inside SwiftUI.
@MainActor
struct PDFKitView {
    /// The PDF document to display.
    let document: PDFDocument
    /// The scroll direction used by the PDF view.
    let direction: PDFDisplayDirection
    /// The currently selected page index.
    @Binding var currentPageIndex: Int

    /// Creates a configured `PDFView` instance.
    ///
    /// - Returns: A PDF view ready for display.
    private func makePDFView() -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayDirection = direction
        pdfView.displayMode = .singlePageContinuous
        pdfView.backgroundColor = .clear
        return pdfView
    }

    /// Updates the PDF view to show the requested page.
    ///
    /// - Parameter pdfView: The PDF view to update.
    private func updatePDFView(_ pdfView: PDFView) {
        guard let document = pdfView.document,
              currentPageIndex >= 0,
              currentPageIndex < document.pageCount,
              let page = document.page(at: currentPageIndex)
        else { fatalError("Error encountering page number of PDF") }
        pdfView.go(to: page)
    }
}

#if os(macOS)
import AppKit

extension PDFKitView: NSViewRepresentable {
    /// Creates the macOS PDF view.
    ///
    /// - Parameter context: The representable context.
    /// - Returns: The configured PDF view.
    func makeNSView(context _: Context) -> PDFView {
        makePDFView()
    }

    /// Updates the macOS PDF view.
    ///
    /// - Parameters:
    ///   - nsView: The PDF view to update.
    ///   - context: The representable context.
    func updateNSView(_ nsView: PDFView, context _: Context) {
        updatePDFView(nsView)
    }
}
#else
extension PDFKitView: UIViewRepresentable {
    /// Creates the iOS PDF view.
    ///
    /// - Parameter context: The representable context.
    /// - Returns: The configured PDF view.
    func makeUIView(context _: Context) -> PDFView {
        makePDFView()
    }

    /// Updates the iOS PDF view.
    ///
    /// - Parameters:
    ///   - uiView: The PDF view to update.
    ///   - context: The representable context.
    func updateUIView(_ uiView: PDFView, context _: Context) {
        updatePDFView(uiView)
    }
}
#endif
