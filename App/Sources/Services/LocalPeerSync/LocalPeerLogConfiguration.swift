//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

/// Configures runtime behavior for local peer sync debug logging.
enum LocalPeerLogConfiguration {
    /// Controls whether local peer sync logs are emitted.
    static let isEnabled: Bool = true
}

/// Emits one local peer sync log message when logging is enabled.
///
/// - Parameter message: The lazily constructed log message.
@inline(__always)
func localPeerLog(_ message: @autoclosure () -> String) {
    guard LocalPeerLogConfiguration.isEnabled else {
        return
    }
    print(message())
}
