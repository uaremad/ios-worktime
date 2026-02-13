//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

public struct ExportInformation: Identifiable {
    public var id: UUID = .init()
    public var pdfUrl: URL

    public init(pdfUrl: URL) {
        self.pdfUrl = pdfUrl
    }
}
