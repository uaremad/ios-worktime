//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation
import Observation

/// Manages the state and logic for export preview and export execution.
@MainActor
@Observable
final class ExportPreviewViewModel {
    /// The selected export format.
    var selectedFormat: ExportFormat

    /// Whether to include comments in the export.
    var includeComments: Bool = false

    /// Whether to include pulse pressure in the export.
    var includePulsePressure: Bool = false

    /// Whether PDF export should use grayscale colors only.
    var useBlackAndWhitePrint: Bool = false

    /// Whether an export operation is currently in progress.
    var isExporting: Bool = false

    /// The activity item for sharing the exported file.
    var exportActivityItem: ExportActivityItem?

    /// The prepared export file used for preview and later sharing.
    var preparedExportItem: PreparedExportItem?

    /// Indicates whether an export preparation error alert should be shown.
    var showsPreparationErrorAlert: Bool = false

    /// Stores the latest error message from export preparation.
    var preparationErrorMessage: String = ""

    /// The measurements to export.
    var measurements: [TimeRecords] = []

    /// The locale identifier used for export date and number formatting.
    ///
    /// This value should be kept in sync with the SwiftUI `Environment` locale by the owning view.
    var localeIdentifier: String = Locale.current.identifier

    /// The effective locale used for export formatting.
    var exportLocale: Locale {
        Locale(identifier: localeIdentifier)
    }

    /// A formatted string representing the export period.
    ///
    /// - Note: This is used by the export preview UI.
    var periodString: String {
        let formatter = DateFormatter()
        formatter.locale = exportLocale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    /// The start date for the export range.
    let startDate: Date

    /// The end date for the export range.
    let endDate: Date

    /// The Core Data managed object context.
    private let context: NSManagedObjectContext

    /// Creates an export preview view model.
    ///
    /// - Parameters:
    ///   - startDate: The start date for the export range.
    ///   - endDate: The end date for the export range.
    ///   - context: The Core Data managed object context.
    ///   - initialFormat: The initially selected export format.
    init(
        startDate: Date,
        endDate: Date,
        context: NSManagedObjectContext,
        initialFormat: ExportFormat = .csv
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.context = context
        selectedFormat = initialFormat
    }
}

extension ExportPreviewViewModel {
    /// Loads measurements from the selected date range.
    func loadMeasurements() {
        let calendar = Calendar.current

        var startComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
        startComponents.hour = 0
        startComponents.minute = 0
        startComponents.second = 0
        guard let adjustedStart = calendar.date(from: startComponents) else { return }

        var endComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
        endComponents.hour = 23
        endComponents.minute = 59
        endComponents.second = 59
        guard let adjustedEnd = calendar.date(from: endComponents) else { return }

        let fetchRequest: NSFetchRequest<TimeRecords> = TimeRecords.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "(dtmMeasured >= %@) AND (dtmMeasured <= %@)",
            adjustedStart as NSDate,
            adjustedEnd as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dtmMeasured", ascending: false)]

        do {
            measurements = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching measurements: \(error)")
            measurements = []
        }
    }

    /// Prepares the export file based on the selected format.
    ///
    /// This method generates the target file but does not open the share sheet.
    /// Instead, it stores a prepared item for the next preview/export step.
    func prepareExport() {
        isExporting = true
        showsPreparationErrorAlert = false
        preparationErrorMessage = ""

        Task {
            do {
                let fileURL: URL = switch selectedFormat {
                case .csv:
                    try await exportToCSV()
                case .pdf:
                    try await exportToPDF()
                }

                preparedExportItem = PreparedExportItem(
                    format: selectedFormat,
                    url: fileURL
                )
            } catch {
                print("Export preparation error: \(error)")
                preparationErrorMessage = error.localizedDescription
                showsPreparationErrorAlert = true
            }

            isExporting = false
        }
    }
}

/// An identifiable wrapper for export activity items.
struct ExportActivityItem: Identifiable {
    /// The stable identity used for SwiftUI lists and sheets.
    let id = UUID()
    /// The exported file URL.
    let url: URL
}

/// A prepared export payload used by the preview-and-share step.
struct PreparedExportItem: Identifiable, Hashable {
    /// Stable identity for navigation.
    let id = UUID()
    /// The prepared export format.
    let format: ExportFormat
    /// The generated export file location.
    let url: URL
}

/// Errors that can occur during export.
enum ExportError: Error {
    /// The PDF generator did not return a result URL.
    case pdfGenerationFailed
}
