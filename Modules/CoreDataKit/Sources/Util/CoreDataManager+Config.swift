//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

public extension CoreDataManager {
    /// Indicates whether iCloud synchronization is enabled for the shared manager.
    static var isCloud: Bool {
        guard let shared else { return false }
        if case .container = shared.iCloudSyncMode {
            return true
        }
        return false
    }

    /// Returns the current store name for the shared manager.
    static var storageName: String {
        guard let url = storeUrl else { return "" }
        return url.deletingPathExtension().lastPathComponent
    }

    /// Returns the current store size in bytes for the shared manager.
    static var storageSize: Int64 {
        guard let url = storeUrl else { return 0 }
        return fileSize(at: url) ?? 0
    }

    /// Returns the last store modification date as a proxy for the last sync date.
    static var lastSyncDate: Date? {
        guard let url = storeUrl else { return nil }
        return fileModificationDate(at: url)
    }

    /// Returns the URL of the first persistent store for the shared manager.
    private static var storeUrl: URL? {
        guard let shared else { return nil }
        return shared.persistentContainer.persistentStoreCoordinator.persistentStores.first?.url
    }

    /// Returns the file size at a given URL.
    ///
    /// - Parameter url: The file URL to inspect.
    /// - Returns: The file size in bytes.
    private static func fileSize(at url: URL) -> Int64? {
        let path = url.path
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }

    /// Returns the file modification date at a given URL.
    ///
    /// - Parameter url: The file URL to inspect.
    /// - Returns: The file modification date.
    private static func fileModificationDate(at url: URL) -> Date? {
        let path = url.path
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }
}
