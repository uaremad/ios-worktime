//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

extension ExportPreviewViewModel {
    /// Exports time records to a CSV file.
    ///
    /// - Returns: The URL of the generated CSV file.
    func exportToCSV() async throws -> URL {
        let filename = exportFilename(fileExtension: "csv")
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        let columns: [String] = [
            L10n.generalImportFieldDate,
            L10n.accessibilityExportStartDate,
            L10n.accessibilityExportEndDate
        ]

        var csvString = columns.joined(separator: ";")
        csvString += "\n"

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
            csvString += "\(date);\(startTime);\(endTime)"
            csvString += "\n"
        }

        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
