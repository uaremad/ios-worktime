//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

extension ExportPreviewViewModel {
    /// Builds a placeholder export filename for the given extension.
    ///
    /// - Parameter fileExtension: The target file extension without a leading dot.
    /// - Returns: A safe placeholder filename.
    func exportFilename(fileExtension: String) -> String {
        let timestamp = DateFormatter.filenameDateFormatter.string(from: Date())
        return "export-\(timestamp).\(fileExtension)"
    }
}

private extension DateFormatter {
    /// A stable date formatter for export filenames.
    static let filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return formatter
    }()
}
