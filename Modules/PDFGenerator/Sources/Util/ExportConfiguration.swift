//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

public struct ExportConfiguration {
    /// Represents common paper sizes with their dimensions.
    ///
    /// You can use the `dimensions` property to get the width and height of each paper size in points.
    ///
    /// - Note: The dimensions are calculated based on the standard DPI (dots per inch) of 72 for print.
    public enum PaperSize {
        /// Standard US Letter paper size.
        case usLetter
        /// Standard DIN A4 paper size.
        case dinA4

        /// Provides the dimensions of the paper in points.
        ///
        /// - Returns: A tuple containing the width and height of the paper in points.
        var dimensions: (width: CGFloat, height: CGFloat) {
            let pointsPerInch: CGFloat = 72.0

            switch self {
            case .usLetter:
                let widthInInches: CGFloat = 8.5
                let heightInInches: CGFloat = 11.0
                return (widthInInches * pointsPerInch, heightInInches * pointsPerInch)
            case .dinA4:
                let widthInInches: CGFloat = 8.3
                let heightInInches: CGFloat = 11.7
                return (widthInInches * pointsPerInch, heightInInches * pointsPerInch)
            }
        }
    }

    let letterTitle: String
    let paperSize: PaperSize
    let includingTimestamp: Bool

    /// Creates an `ExportConfiguration` specifying the properties of the exported consent form.
    /// - Parameters:
    ///   - paperSize: The page size of the exported
    ///   - letterTitle: The title of the exported letter
    ///   - includingTimestamp: Indicates if the exported form includes a timestamp.
    public init(
        paperSize: PaperSize = .usLetter,
        letterTitle: String = "",
        includingTimestamp: Bool = true
    ) {
        self.paperSize = paperSize
        self.letterTitle = letterTitle
        self.includingTimestamp = includingTimestamp
    }
}
