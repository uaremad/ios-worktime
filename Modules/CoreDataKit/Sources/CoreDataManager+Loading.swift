//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData

/// An extension providing additional functionality to the `CoreDataManager` class.
extension CoreDataManager {
    /// Loads a managed object model either from a bundle or a URL.
    ///
    /// - Parameters:
    ///   - bundle: The bundle containing the Core Data model. If nil, `url` must be provided.
    ///   - url: The file URL of the Core Data model. If nil, `bundle` must be provided.
    ///   - modelName: The name of the Core Data model.
    /// - Returns: The loaded managed object model, or nil if failed to load.
    static func loadModel(bundle: Bundle?, use url: URL?, modelName: String) -> NSManagedObjectModel? {
        guard bundle == nil, let url else {
            guard let bundle, let fileURL = bundle.url(forResource: modelName, withExtension: "momd") else {
                return nil
            }
            print("CoreDataManager: Found MOM file at: \(fileURL.path)")
            return NSManagedObjectModel(contentsOf: fileURL)
        }
        print("CoreDataManager: Found MOM file at: \(url.path)")
        return NSManagedObjectModel(contentsOf: url)
    }
}
