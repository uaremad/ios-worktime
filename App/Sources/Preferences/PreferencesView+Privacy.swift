//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if os(macOS)
import SwiftUI

extension PreferencesView {
    /// The privacy preferences section using the shared privacy policy screen.
    var privacyView: some View {
        PrivacyPolicyView()
    }
}
#endif
