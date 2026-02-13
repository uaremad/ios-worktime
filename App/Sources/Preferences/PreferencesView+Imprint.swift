//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if os(macOS)
import SwiftUI

extension PreferencesView {
    /// The imprint preferences section using the shared imprint screen.
    var imprintView: some View {
        ImprintView()
    }
}
#endif
