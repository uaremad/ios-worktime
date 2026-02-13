//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import PDFKit
import SwiftUI

public protocol TemplateProtocol: View {
    var attributedText: AttributedString { get set }
}

public extension TemplateProtocol {
    func setText(_ attributedText: AttributedString) -> Self {
        var copy = self
        copy.attributedText = attributedText
        return copy
    }
}
