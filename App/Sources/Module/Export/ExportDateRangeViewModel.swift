//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation
import SwiftUI

/// Manages the state and logic for export date range selection.
@MainActor
@Observable
final class ExportDateRangeViewModel {
    /// The start date for the export range.
    var startDate: Date

    /// The end date for the export range.
    var endDate: Date

    /// The number of measurements in the selected date range.
    var measurementCount: Int = 0

    /// The Core Data managed object context.
    private let context: NSManagedObjectContext

    /// Creates an export date range view model.
    ///
    /// - Parameter context: The Core Data managed object context.
    init(context: NSManagedObjectContext) {
        self.context = context

        // Set default date range (first day of current year to today)
        let calendar = Calendar.current
        let now = Date()

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0

        startDate = calendar.date(from: components) ?? now
        endDate = now
    }

    /// Updates the measurement count based on the current date range.
    func updateMeasurementCount() {
        let calendar = Calendar.current

        // Adjust start date to beginning of day
        var startComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
        startComponents.hour = 0
        startComponents.minute = 0
        startComponents.second = 0
        guard let adjustedStart = calendar.date(from: startComponents) else { return }

        // Adjust end date to end of day
        var endComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
        endComponents.hour = 23
        endComponents.minute = 59
        endComponents.second = 59
        guard let adjustedEnd = calendar.date(from: endComponents) else { return }

        // Create fetch request
        let fetchRequest: NSFetchRequest<TimeRecords> = TimeRecords.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "(dtmMeasured >= %@) AND (dtmMeasured <= %@)",
            adjustedStart as NSDate,
            adjustedEnd as NSDate
        )

        // Count measurements
        do {
            measurementCount = try context.count(for: fetchRequest)
        } catch {
            print("Error counting measurements: \(error)")
            measurementCount = 0
        }
    }
}
