//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import SwiftUI

public struct BlankPage: TemplateProtocol {
    public var attributedText: AttributedString

    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(attributedText)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            Spacer()
        }
    }

    public init(_ attributedText: AttributedString = AttributedString("")) {
        self.attributedText = attributedText
    }
}
