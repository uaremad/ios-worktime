//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import PDFKit
import SwiftUI

public class PDFGenerator {
    public init() {}

    @MainActor
    public func pdf(for view: any TemplateProtocol) async -> ExportInformation? {
        await pdf(for: [view])
    }

    /// Generates a PDF document containing one page per template view.
    ///
    /// - Parameter views: The ordered template views to render as individual pages.
    /// - Returns: Export metadata with URL if rendering succeeds, otherwise `nil`.
    @MainActor
    public func pdf(for views: [any TemplateProtocol]) async -> ExportInformation? {
        guard views.isEmpty == false else { return nil }

        let exportConfiguration: ExportConfiguration = .init(paperSize: .dinA4, letterTitle: "my title", includingTimestamp: true)
        let paperSize = CGSize(
            width: exportConfiguration.paperSize.dimensions.width,
            height: exportConfiguration.paperSize.dimensions.height
        )

        let url = URL.documentsDirectory.appending(path: "generatedPDF.pdf")

        return await withCheckedContinuation { continuation in
            var box = CGRect(origin: .zero, size: paperSize)

            /// Create in-memory `CGContext` that stores the PDF
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                continuation.resume(returning: nil)
                return
            }

            for view in views {
                let renderer = ImageRenderer(content: AnyView(view))
                renderer.proposedSize = .init(paperSize)

                pdf.beginPDFPage(nil)
                pdf.translateBy(x: 0, y: 0)
                renderer.render { _, context in
                    context(pdf)
                }
                pdf.endPDFPage()
            }

            pdf.closePDF()
            continuation.resume(returning: ExportInformation(pdfUrl: url))
        }
    }
}
