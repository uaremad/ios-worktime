//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if os(macOS)
import SwiftUI

extension PreferencesView {
    /// The iOS synchronization preferences section using the shared host intro screen.
    var iosSynchronizationView: some View {
        LocalPeerSyncHostIntroView()
    }
}
#endif
