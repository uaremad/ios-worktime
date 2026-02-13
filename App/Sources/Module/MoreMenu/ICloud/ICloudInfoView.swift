//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import CoreDataKit
import SwiftUI

/// Presents details about iCloud storage and synced entity counts.
@MainActor
struct ICloudInfoView: View {
    /// Provides access to the current managed object context.
    @Environment(\.managedObjectContext) private var viewContext

    /// Stores the last CloudKit sync event date.
    @State private var lastCloudSyncDate: Date?
    /// Stores the count of time records.
    @State private var timeRecordCount = 0

    /// Renders the iCloud details view.
    var body: some View {
        List {
            Section("Status") {
                infoRow(title: "iCloud", value: isCloudEnabled ? "Aktiv" : "Deaktiviert")
                infoRow(title: "Store", value: storageNameText)
                infoRow(title: "Store-Größe", value: storageSizeText)
                infoRow(title: "Letzte Synchronisierung", value: lastSyncText)
            }

            Section("Daten") {
                infoRow(title: "Zeiteinträge", value: "\(timeRecordCount)")
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .scrollContentBackground(.hidden)
        .background(Color.aBackground)
        .navigationTitle("iCloud Details")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .onReceive(NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)) { notification in
                updateLastCloudSyncDate(from: notification)
            }
            .task {
                await loadCounts()
            }
    }
}

private extension ICloudInfoView {
    /// Indicates whether iCloud sync is enabled for the shared Core Data stack.
    var isCloudEnabled: Bool {
        CoreDataManager.isCloud
    }

    /// Returns the current storage name text.
    var storageNameText: String {
        let value = CoreDataManager.storageName
        return value.isEmpty ? "-" : value
    }

    /// Returns the current storage size text.
    var storageSizeText: String {
        let size = CoreDataManager.storageSize
        if size <= 0 {
            return "-"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// Returns the formatted last sync date text.
    var lastSyncText: String {
        guard isCloudEnabled else {
            return "Deaktiviert"
        }
        guard let date = lastCloudSyncDate else {
            return "-"
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    /// Builds one key-value information row.
    ///
    /// - Parameters:
    ///   - title: The row title.
    ///   - value: The row value.
    /// - Returns: A horizontal information row.
    func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .textStyle(.body3)
                .foregroundStyle(Color.aPrimary.opacity(0.7))
            Spacer()
            Text(value)
                .textStyle(.body2)
                .foregroundStyle(Color.aPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    /// Updates the last cloud sync date when a CloudKit event succeeds.
    ///
    /// - Parameter notification: The cloud event notification.
    func updateLastCloudSyncDate(from notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
            as? NSPersistentCloudKitContainer.Event
        else {
            return
        }
        guard event.succeeded else {
            return
        }
        lastCloudSyncDate = event.endDate ?? event.startDate
    }

    /// Loads displayed entity counts from the active Core Data store.
    func loadCounts() async {
        do {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "TimeRecords")
            let count = try viewContext.count(for: request)
            timeRecordCount = count
        } catch {
            timeRecordCount = 0
        }
    }
}
