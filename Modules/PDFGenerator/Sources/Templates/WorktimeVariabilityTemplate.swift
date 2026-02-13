//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import SwiftUI

/// A PDF page template showing statistical variability for measurement series.
public struct WorktimeVariabilityTemplate: TemplateProtocol {
    /// Mutable attributed text payload required by `TemplateProtocol`.
    public var attributedText: AttributedString

    /// The shared horizontal cell padding used by header and data cells.
    private let tableCellHorizontalPadding: CGFloat = 6

    /// The period string displayed below the page title.
    let periodString: String

    /// The measurements used to compute variability metrics.
    let measurements: [MeasurementData]

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Statistische Variabilität")
                .font(.system(size: 24, weight: .bold))

            Text(periodString)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)

            variabilityTable

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The table containing descriptive variability metrics for each series.
    private var variabilityTable: some View {
        let systolicStats = StatisticalMetrics(values: measurements.map(\.systolic))
        let diastolicStats = StatisticalMetrics(values: measurements.map(\.diastolic))
        let pulseStats = StatisticalMetrics(values: measurements.map(\.pulse))

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                headerCell("Wert", alignment: .leading, width: nil)
                headerCell("Mittel", alignment: .center, width: 80)
                headerCell("Min", alignment: .center, width: 80)
                headerCell("Max", alignment: .center, width: 80)
                headerCell("Spannweite", alignment: .center, width: 100)
                headerCell("StdAbw", alignment: .center, width: 80)
            }
            .background(Color.gray.opacity(0.15))

            metricRow(title: "Systolisch", metrics: systolicStats)
            metricRow(title: "Diastolisch", metrics: diastolicStats)
            metricRow(title: "Puls", metrics: pulseStats)
        }
        .border(Color.gray.opacity(0.5), width: 1)
    }

    /// Creates one table row for a metric series.
    ///
    /// - Parameters:
    ///   - title: The row title.
    ///   - metrics: The calculated statistical metrics.
    /// - Returns: A styled metric row.
    private func metricRow(title: String, metrics: StatisticalMetrics) -> some View {
        HStack(spacing: 0) {
            dataCell(title, alignment: .leading, width: nil)
            dataCell(metrics.meanString, alignment: .center, width: 80)
            dataCell(metrics.minString, alignment: .center, width: 80)
            dataCell(metrics.maxString, alignment: .center, width: 80)
            dataCell(metrics.rangeString, alignment: .center, width: 100)
            dataCell(metrics.standardDeviationString, alignment: .center, width: 80)
        }
    }

    /// Creates a table header cell.
    ///
    /// - Parameters:
    ///   - text: The header title text.
    ///   - alignment: The horizontal content alignment.
    ///   - width: Optional fixed width for the cell.
    /// - Returns: A styled table header cell.
    private func headerCell(_ text: String, alignment: Alignment, width: CGFloat?) -> some View {
        Group {
            if let width {
                Text(text)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.7)
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
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity, minHeight: 30, alignment: alignment)
                    .padding(.horizontal, tableCellHorizontalPadding)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            }
        }
    }

    /// Creates a table data cell.
    ///
    /// - Parameters:
    ///   - text: The cell text content.
    ///   - alignment: The horizontal content alignment.
    ///   - width: Optional fixed width for the cell.
    /// - Returns: A styled table data cell.
    private func dataCell(_ text: String, alignment: Alignment, width: CGFloat?) -> some View {
        Group {
            if let width {
                Text(text)
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)
                    .frame(width: width, alignment: alignment)
                    .frame(minHeight: 26, alignment: alignment)
                    .padding(.horizontal, tableCellHorizontalPadding)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            } else {
                Text(text)
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity, minHeight: 26, alignment: alignment)
                    .padding(.horizontal, tableCellHorizontalPadding)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            }
        }
    }

    public init(
        periodString: String,
        measurements: [MeasurementData],
        attributedText: AttributedString = AttributedString("")
    ) {
        self.periodString = periodString
        self.measurements = measurements
        self.attributedText = attributedText
    }
}

/// Descriptive statistics for one numeric series.
private struct StatisticalMetrics {
    /// The value count used for calculations.
    let count: Int
    /// The arithmetic mean.
    let mean: Double
    /// The minimum value.
    let minimum: Int
    /// The maximum value.
    let maximum: Int
    /// The standard deviation.
    let standardDeviation: Double

    /// The range width (`max - min`).
    var range: Int { maximum - minimum }

    /// Mean value formatted with one fraction digit.
    var meanString: String { formattedDouble(mean) }

    /// Minimum value as text.
    var minString: String { count > 0 ? "\(minimum)" : "-" }

    /// Maximum value as text.
    var maxString: String { count > 0 ? "\(maximum)" : "-" }

    /// Range value as text.
    var rangeString: String { count > 0 ? "\(range)" : "-" }

    /// Standard deviation formatted with one fraction digit.
    var standardDeviationString: String { formattedDouble(standardDeviation) }

    /// Creates metrics for one integer value list.
    ///
    /// - Parameter values: The source values.
    init(values: [Int]) {
        count = values.count
        guard values.isEmpty == false else {
            mean = 0
            minimum = 0
            maximum = 0
            standardDeviation = 0
            return
        }

        minimum = values.min() ?? 0
        maximum = values.max() ?? 0
        let sum = values.reduce(0, +)
        let meanValue = Double(sum) / Double(values.count)
        mean = meanValue
        let variance = values
            .map { pow(Double($0) - meanValue, 2) }
            .reduce(0, +) / Double(values.count)
        standardDeviation = sqrt(variance)
    }

    /// Formats one `Double` with one decimal place.
    ///
    /// - Parameter value: The number to format.
    /// - Returns: A decimal string or `"-"` for empty datasets.
    private func formattedDouble(_ value: Double) -> String {
        guard count > 0 else { return "-" }
        return String(format: "%.1f", value)
    }
}
