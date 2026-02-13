//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

/// An extension to safely access elements in an array by index, avoiding index out of range errors.
public extension Array {
    /// Accesses the element at the specified position safely.
    ///
    /// - Parameters:
    ///   - safe: The index of the element to access safely.
    /// - Returns: The element at the specified index if it exists, or nil if the index is out of range.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
