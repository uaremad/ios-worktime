//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import PDFGenerator

extension ExportPreviewViewModel {
    /// Exports time records to a PDF file.
    ///
    /// - Returns: The URL of the generated PDF file.
    func exportToPDF() async throws -> URL {
        let filename = exportFilename(fileExtension: "pdf")
        let tempDir = FileManager.default.temporaryDirectory
        let targetURL = tempDir.appendingPathComponent(filename)

        var attributedText = AttributedString("\(periodString)\n")
        attributedText.append(AttributedString("\(L10n.exportPreviewMeasurementCount(measurements.count))\n\n"))

        let dateFormatter = DateFormatter()
        dateFormatter.locale = exportLocale
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        let timeFormatter = DateFormatter()
        timeFormatter.locale = exportLocale
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        for record in measurements {
            let startDate = record.dtmStart ?? record.dtmEnd ?? Date()
            let endDate = record.dtmEnd ?? record.dtmStart ?? startDate
            let date = dateFormatter.string(from: startDate)
            let startTime = timeFormatter.string(from: startDate)
            let endTime = timeFormatter.string(from: endDate)
            attributedText.append(AttributedString("\(date): \(startTime) - \(endTime)\n"))
        }

        let generator = PDFGenerator()
        guard let exportInfo = await generator.pdf(for: BlankPage(attributedText)) else {
            throw ExportError.pdfGenerationFailed
        }

        try? FileManager.default.removeItem(at: targetURL)
        try FileManager.default.moveItem(at: exportInfo.pdfUrl, to: targetURL)
        return targetURL
    }
}
