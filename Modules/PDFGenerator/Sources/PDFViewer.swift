//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import PDFKit
import SwiftUI

/// A SwiftUI wrapper that displays a PDF document with a simple handle indicator.
public struct PDFViewer: View {
    /// The zero-based index of the currently visible page.
    @State private var currentPageIndex = 0
    /// The PDF document to display.
    private let document: PDFDocument?
    /// Controls whether the top handle indicator is visible.
    private let showsHandle: Bool
    /// Horizontal padding applied to the embedded PDF view.
    private let contentHorizontalPadding: CGFloat

    /// Creates a PDF viewer for a given PDF file URL.
    ///
    /// - Parameters:
    ///   - url: The file URL of the PDF document.
    ///   - showsHandle: Controls whether a drag-handle indicator is rendered.
    ///   - contentHorizontalPadding: Horizontal inset for the PDF content.
    public init(
        url: URL,
        showsHandle: Bool = true,
        contentHorizontalPadding: CGFloat = 20
    ) {
        self.showsHandle = showsHandle
        self.contentHorizontalPadding = contentHorizontalPadding
        guard let document = PDFDocument(url: url) else {
            self.document = nil
            return
        }
        self.document = document
    }

    /// The content and behavior of the view.
    public var body: some View {
        VStack(spacing: 0) {
            if showsHandle {
                Rectangle()
                    .foregroundColor(Color.secondary.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .cornerRadius(2.5)
                    .padding()
            }

            if let document {
                PDFKitView(
                    document: document,
                    direction: .vertical,
                    currentPageIndex: $currentPageIndex
                )
                .padding(.horizontal, contentHorizontalPadding)
            }
            Spacer()
        }
        .background(.clear)
    }
}
