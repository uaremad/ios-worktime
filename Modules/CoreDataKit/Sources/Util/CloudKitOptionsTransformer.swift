//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// A structure representing a transformer for CloudKit options.
struct CloudKitOptionsTransformer {
    /// A closure that transforms the CloudKit options.
    let transform: (NSPersistentCloudKitContainerOptions) -> Void

    /// Initializes the CloudKit options transformer with the given transformation closure.
    ///
    /// - Parameter transform: The transformation closure.
    public init(_ transform: @escaping (NSPersistentCloudKitContainerOptions) -> Void) {
        self.transform = transform
    }
}
