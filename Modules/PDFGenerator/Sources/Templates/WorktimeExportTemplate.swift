//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import SwiftUI

/// A PDF template for blood pressure measurement exports.
///
/// This template displays blood pressure measurements in a table format
/// with averages and individual readings, matching the legacy HTML export format.
public struct WorktimeExportTemplate: TemplateProtocol {
    public var attributedText: AttributedString

    /// The shared horizontal cell padding used by header and data cells.
    private let tableCellHorizontalPadding: CGFloat = 6

    /// The title/name for the export.
    let title: String

    /// The period string (e.g., "01.01.2026 - 31.01.2026").
    let periodString: String

    /// The measurements to display.
    let measurements: [MeasurementData]

    /// Whether to include comments in the export.
    let includeComments: Bool

    /// Whether to include pulse pressure in the export.
    let includePulsePressure: Bool

    /// The injected export color palette.
    let palette: WorktimeExportColorPalette

    /// The locale used for localized date and number formatting.
    let locale: Locale

    /// The injected localization used for all user-facing strings.
    let localization: WorktimePDFLocalization

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text(localization.documentTitle)
                .font(.system(size: 24, weight: .bold))

            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }

            // Average table
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.averageValuesTitle)
                    .font(.system(size: 14, weight: .semibold))

                averageTable
            }

            // Individual measurements table
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.individualMeasurementsTitle)
                    .font(.system(size: 14, weight: .semibold))

                measurementsTable
            }

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The average values table.
    private var averageTable: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                tableHeaderCell(localization.periodTitle, alignment: .leading, width: nil)
                tableHeaderCell(localization.systolicTitle, alignment: .center, width: 70)
                tableHeaderCell(localization.diastolicTitle, alignment: .center, width: 70)
                tableHeaderCell(localization.pulseTitle, alignment: .center, width: 70)
                if includePulsePressure {
                    tableHeaderCell(localization.pulsePressureTitle, alignment: .center, width: 90)
                }
                if includeComments {
                    tableHeaderCell(localization.commentTitle, alignment: .leading, width: nil)
                }
            }
            .background(Color.gray.opacity(0.15))

            // Average row
            if !measurements.isEmpty {
                let avgSystolic = Int(measurements.map { Double($0.systolic) }.reduce(0, +) / Double(measurements.count))
                let avgDiastolic = Int(measurements.map { Double($0.diastolic) }.reduce(0, +) / Double(measurements.count))
                let avgPulse = Int(measurements.map { Double($0.pulse) }.reduce(0, +) / Double(measurements.count))

                HStack(spacing: 0) {
                    tableDataCell(periodString, alignment: .leading, width: nil, color: classificationColor(for: avgSystolic))
                    tableDataCell("\(avgSystolic)", alignment: .center, width: 70)
                    tableDataCell("\(avgDiastolic)", alignment: .center, width: 70)
                    tableDataCell("\(avgPulse)", alignment: .center, width: 70)
                    if includePulsePressure {
                        tableDataCell("\(avgSystolic - avgDiastolic)", alignment: .center, width: 90)
                    }
                    if includeComments {
                        tableDataCell("", alignment: .leading, width: nil)
                    }
                }
                .border(Color.gray.opacity(0.3), width: 1)
            }
        }
        .border(Color.gray.opacity(0.5), width: 1)
    }

    /// The individual measurements table.
    private var measurementsTable: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                tableHeaderCell(localization.dateTitle, alignment: .leading, width: nil)
                tableHeaderCell(localization.systolicTitle, alignment: .center, width: 70)
                tableHeaderCell(localization.diastolicTitle, alignment: .center, width: 70)
                tableHeaderCell(localization.pulseTitle, alignment: .center, width: 70)
                if includePulsePressure {
                    tableHeaderCell(localization.pulsePressureTitle, alignment: .center, width: 90)
                }
                if includeComments {
                    tableHeaderCell(localization.commentTitle, alignment: .leading, width: nil)
                }
            }
            .background(Color.gray.opacity(0.15))

            // Data rows
            ForEach(measurements) { measurement in
                HStack(spacing: 0) {
                    tableDataCell(
                        formattedMeasurementDate(measurement.date),
                        alignment: .leading,
                        width: nil,
                        color: classificationColor(for: measurement.systolic)
                    )
                    tableDataCell("\(measurement.systolic)", alignment: .center, width: 70)
                    tableDataCell("\(measurement.diastolic)", alignment: .center, width: 70)
                    tableDataCell("\(measurement.pulse)", alignment: .center, width: 70)
                    if includePulsePressure {
                        let pulsePressure = measurement.systolic - measurement.diastolic
                        tableDataCell("\(pulsePressure)", alignment: .center, width: 90)
                    }
                    if includeComments {
                        tableDataCell(measurement.comment ?? "", alignment: .leading, width: nil)
                    }
                }
                .border(Color.gray.opacity(0.3), width: 1)
            }
        }
        .border(Color.gray.opacity(0.5), width: 1)
    }

    /// Creates a table header cell.
    private func tableHeaderCell(_ text: String, alignment: Alignment, width: CGFloat?) -> some View {
        Group {
            if let width {
                Text(text)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.75)
                    .allowsTightening(true)
                    .frame(width: width, alignment: alignment)
                    .frame(minHeight: 30, alignment: alignment)
                    .padding(.horizontal, tableCellHorizontalPadding)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            } else {
                Text(text)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.75)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity, minHeight: 30, alignment: alignment)
                    .padding(.horizontal, tableCellHorizontalPadding)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            }
        }
    }

    /// Creates a table data cell.
    private func tableDataCell(_ text: String, alignment: Alignment, width: CGFloat?, color: Color? = nil) -> some View {
        ZStack(alignment: .trailing) {
            Group {
                if let width {
                    Text(text)
                        .font(.system(size: 10))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.8)
                        .allowsTightening(true)
                        .frame(width: width, alignment: alignment)
                        .frame(minHeight: 25, alignment: alignment)
                        .padding(.horizontal, tableCellHorizontalPadding)
                } else {
                    Text(text)
                        .font(.system(size: 10))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.8)
                        .allowsTightening(true)
                        .frame(maxWidth: .infinity, minHeight: 25, alignment: alignment)
                        .padding(.horizontal, tableCellHorizontalPadding)
                }
            }

            if let color {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .padding(.trailing, 6)
            }
        }
        .border(Color.gray.opacity(0.3), width: 0.5)
    }

    /// Returns the classification color for a systolic value.
    private func classificationColor(for systolic: Int) -> Color {
        switch systolic {
        case 0 ..< 105:
            palette.low.color
        case 105 ..< 120:
            palette.optimal.color
        case 120 ..< 130:
            palette.normal.color
        case 130 ..< 140:
            palette.highNormal.color
        case 140 ..< 160:
            palette.hypertensionGrade1.color
        case 160 ..< 180:
            palette.hypertensionGrade2.color
        case 180...:
            palette.hypertensionGrade3.color
        default:
            Color.white
        }
    }

    /// Formats a measurement date using the injected locale.
    ///
    /// - Parameter date: The measurement date.
    /// - Returns: A localized date string suitable for table rendering.
    private func formattedMeasurementDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .day()
                .month(.wide)
                .year()
                .hour()
                .minute()
                .locale(locale)
        )
    }

    public init(
        title: String = "",
        periodString: String,
        measurements: [MeasurementData],
        includeComments: Bool,
        includePulsePressure: Bool,
        locale: Locale,
        localization: WorktimePDFLocalization,
        palette: WorktimeExportColorPalette = .default,
        attributedText: AttributedString = AttributedString("")
    ) {
        self.title = title
        self.periodString = periodString
        self.measurements = measurements
        self.includeComments = includeComments
        self.includePulsePressure = includePulsePressure
        self.locale = locale
        self.localization = localization
        self.palette = palette
        self.attributedText = attributedText
    }
}

/// Data structure for a blood pressure measurement.
public struct MeasurementData: Identifiable {
    public let id: UUID
    public let date: Date
    public let systolic: Int
    public let diastolic: Int
    public let pulse: Int
    public let comment: String?

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    public init(id: UUID = UUID(), date: Date, systolic: Int, diastolic: Int, pulse: Int, comment: String? = nil) {
        self.id = id
        self.date = date
        self.systolic = systolic
        self.diastolic = diastolic
        self.pulse = pulse
        self.comment = comment
    }
}
