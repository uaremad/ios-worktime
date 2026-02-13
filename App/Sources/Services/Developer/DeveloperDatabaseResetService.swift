//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if DEBUG
import CoreData
import Foundation

/// Provides debug-only helpers to reset the Core Data store and related support files.
///
/// The reset is intentionally file-based and removes the entire SQLite family (`.sqlite`, `-wal`, `-shm`)
/// including quarantine and backup variants created during migration and recovery.
@MainActor
enum DeveloperDatabaseResetService {
    /// Resets the persistent store files and terminates the app process.
    ///
    /// - Important: This is a debug-only feature. The app process is terminated after cleanup to
    ///   guarantee a clean Core Data stack on the next launch.
    ///
    /// - Parameter managedObjectContext: The active managed object context.
    static func resetStoreAndExit(managedObjectContext: NSManagedObjectContext) {
        resetPersistentDefaults()

        guard let coordinator = managedObjectContext.persistentStoreCoordinator else {
            exit(0)
        }

        let sqliteStores = coordinator.persistentStores.filter { store in
            store.type == NSSQLiteStoreType && store.url != nil
        }

        for store in sqliteStores {
            guard let storeUrl = store.url else {
                continue
            }

            managedObjectContext.performAndWait {
                managedObjectContext.reset()
            }

            do {
                try coordinator.remove(store)
            } catch {
                // Continue with best-effort file cleanup even if Core Data cannot detach the store.
                print("[COREDATA][DEV] Failed to remove persistent store: \(error)")
            }

            removeSQLiteFamily(at: storeUrl)
            removeRelatedSQLiteFiles(at: storeUrl)
            removeLegacyStoreCandidates(primaryStoreUrl: storeUrl)
        }

        exit(0)
    }

    /// Removes all persisted app defaults and purchase metadata.
    ///
    /// - Important: This intentionally clears the full app defaults domain.
    private static func resetPersistentDefaults() {
        #if os(iOS)
        PurchaseStorageService.shared.reset()
        #endif

        let defaults = UserDefaults.standard
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleIdentifier)
        }
        defaults.synchronize()
    }
}

private extension DeveloperDatabaseResetService {
    /// Removes the SQLite family (`.sqlite`, `-wal`, `-shm`) when present.
    ///
    /// - Parameter storeUrl: The base SQLite store URL.
    static func removeSQLiteFamily(at storeUrl: URL) {
        let fileManager = FileManager.default
        let paths = [storeUrl.path, storeUrl.path + "-wal", storeUrl.path + "-shm"]
        for path in paths where fileManager.fileExists(atPath: path) {
            do {
                try fileManager.removeItem(atPath: path)
            } catch {
                print("[COREDATA][DEV] Failed to delete sqlite file: \(error)")
            }
        }
    }

    /// Removes quarantine/backup variants for a given base store name in the same directory.
    ///
    /// - Parameter storeUrl: The primary store URL.
    static func removeRelatedSQLiteFiles(at storeUrl: URL) {
        let fileManager = FileManager.default
        let directoryUrl = storeUrl.deletingLastPathComponent()
        let baseName = storeUrl.deletingPathExtension().lastPathComponent

        guard let files = try? fileManager.contentsOfDirectory(
            at: directoryUrl,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        let candidates = files.filter { url in
            let name = url.lastPathComponent
            guard name.hasPrefix(baseName) else { return false }
            return name.hasSuffix(".sqlite") || name.hasSuffix(".sqlite-wal") || name.hasSuffix(".sqlite-shm")
        }

        for candidate in candidates {
            do {
                try fileManager.removeItem(at: candidate)
            } catch {
                print("[COREDATA][DEV] Failed to delete related store file: \(error)")
            }
        }
    }

    /// Removes legacy store candidates for deterministic repeated testing.
    ///
    /// - Parameter primaryStoreUrl: The current destination store URL.
    static func removeLegacyStoreCandidates(primaryStoreUrl: URL) {
        let legacyBaseNames = ["BPDiaryData", "DataBase"]
        let fileManager = FileManager.default

        for directory in legacyCandidateDirectories(primaryStoreUrl: primaryStoreUrl) {
            for baseName in legacyBaseNames {
                let storeUrl = directory.appendingPathComponent("\(baseName).sqlite")
                if fileManager.fileExists(atPath: storeUrl.path) {
                    removeSQLiteFamily(at: storeUrl)
                    removeRelatedSQLiteFiles(at: storeUrl)
                }
            }
        }
    }

    /// Returns common legacy directories within the app sandbox.
    ///
    /// - Parameter primaryStoreUrl: The current destination store URL.
    /// - Returns: Directory URLs to check for legacy candidates.
    static func legacyCandidateDirectories(primaryStoreUrl: URL) -> [URL] {
        let fileManager = FileManager.default
        var directories: [URL] = [primaryStoreUrl.deletingLastPathComponent()]

        if let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            directories.append(documents)
        }

        if let library = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first {
            directories.append(library.appendingPathComponent("Private Documents"))
            directories.append(library.appendingPathComponent("Application Support"))
        }

        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            directories.append(appSupport)
        }

        // Deduplicate while keeping order.
        var seen: Set<String> = []
        return directories.filter { url in
            let path = url.path
            guard seen.contains(path) == false else { return false }
            seen.insert(path)
            return true
        }
    }
}
#endif
