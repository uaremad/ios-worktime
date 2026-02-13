//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import SwiftUI

/// A PDF page template showing measurement distribution across blood pressure ranges.
public struct WorktimeDistributionTemplate: TemplateProtocol {
    /// Mutable attributed text payload required by `TemplateProtocol`.
    public var attributedText: AttributedString

    /// The shared horizontal cell padding used by header and data cells.
    private let tableCellHorizontalPadding: CGFloat = 6

    /// The period string displayed below the page title.
    let periodString: String

    /// The measurements used to build the distribution.
    let measurements: [MeasurementData]

    /// The injected export color palette.
    let palette: WorktimeExportColorPalette

    /// The locale used for localized date and number formatting.
    let locale: Locale

    /// The injected localization used for all user-facing strings.
    let localization: WorktimePDFLocalization

    /// The shared horizontal cell padding used by variability header and data cells.
    private let variabilityTableCellHorizontalPadding: CGFloat = 6

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(localization.distributionTitle)
                .font(.system(size: 24, weight: .bold))

            Text(periodString)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)

            distributionTable
            variabilitySection

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The table containing counts and percentages per pressure category.
    private var distributionTable: some View {
        let total = max(measurements.count, 1)

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                headerCell(localization.distributionCategoryTitle, alignment: .leading, width: nil)
                headerCell(localization.distributionCountTitle, alignment: .center, width: 90)
                headerCell(localization.distributionShareTitle, alignment: .center, width: 90)
            }
            .background(Color.gray.opacity(0.15))

            ForEach(DistributionCategory.allCases) { category in
                let count = measurements.reduce(into: 0) { partialResult, measurement in
                    if category.matches(systolic: measurement.systolic) {
                        partialResult += 1
                    }
                }
                let percentage = Int((Double(count) / Double(total) * 100).rounded())

                HStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(category.color(in: palette))
                            .frame(width: 10, height: 10)
                        Text(category.title(localization: localization))
                            .font(.system(size: 10))
                    }
                    .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
                    .padding(.horizontal, tableCellHorizontalPadding)
                    .border(Color.gray.opacity(0.3), width: 0.5)

                    dataCell("\(count)", alignment: .center, width: 90)
                    dataCell("\(percentage)%", alignment: .center, width: 90)
                }
            }
        }
        .border(Color.gray.opacity(0.5), width: 1)
    }

    /// The section containing descriptive variability metrics.
    private var variabilitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.variabilityTitle)
                .font(.system(size: 16, weight: .semibold))

            variabilityTable
        }
    }

    /// The table containing descriptive variability metrics for each measurement series.
    private var variabilityTable: some View {
        let systolicStats = StatisticalMetrics(values: measurements.map(\.systolic))
        let diastolicStats = StatisticalMetrics(values: measurements.map(\.diastolic))
        let pulseStats = StatisticalMetrics(values: measurements.map(\.pulse))

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                variabilityHeaderCell(localization.variabilityValueTitle, alignment: .leading, width: nil)
                variabilityHeaderCell(localization.variabilityMeanTitle, alignment: .center, width: 70)
                variabilityHeaderCell(localization.variabilityMinTitle, alignment: .center, width: 60)
                variabilityHeaderCell(localization.variabilityMaxTitle, alignment: .center, width: 60)
                variabilityHeaderCell(localization.variabilityRangeTitle, alignment: .center, width: 90)
                variabilityHeaderCell(localization.variabilityStandardDeviationTitle, alignment: .center, width: 70)
            }
            .background(Color.gray.opacity(0.15))

            variabilityMetricRow(title: localization.systolicTitle, metrics: systolicStats)
            variabilityMetricRow(title: localization.diastolicTitle, metrics: diastolicStats)
            variabilityMetricRow(title: localization.pulseTitle, metrics: pulseStats)
        }
        .border(Color.gray.opacity(0.5), width: 1)
    }

    /// Creates one table row for a variability metric series.
    ///
    /// - Parameters:
    ///   - title: The row title.
    ///   - metrics: The calculated statistical metrics.
    /// - Returns: A styled metric row.
    private func variabilityMetricRow(title: String, metrics: StatisticalMetrics) -> some View {
        HStack(spacing: 0) {
            variabilityDataCell(title, alignment: .leading, width: nil)
            variabilityDataCell(metrics.meanString, alignment: .center, width: 70)
            variabilityDataCell(metrics.minString, alignment: .center, width: 60)
            variabilityDataCell(metrics.maxString, alignment: .center, width: 60)
            variabilityDataCell(metrics.rangeString, alignment: .center, width: 90)
            variabilityDataCell(metrics.standardDeviationString, alignment: .center, width: 70)
        }
    }

    /// Creates a variability table header cell.
    ///
    /// - Parameters:
    ///   - text: The header title text.
    ///   - alignment: The horizontal content alignment.
    ///   - width: Optional fixed width for the cell.
    /// - Returns: A styled variability table header cell.
    private func variabilityHeaderCell(_ text: String, alignment: Alignment, width: CGFloat?) -> some View {
        Group {
            if let width {
                Text(text)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .frame(width: width, alignment: alignment)
                    .frame(minHeight: 24, alignment: alignment)
                    .padding(.horizontal, variabilityTableCellHorizontalPadding)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            } else {
                Text(text)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity, minHeight: 24, alignment: alignment)
                    .padding(.horizontal, variabilityTableCellHorizontalPadding)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            }
        }
    }

    /// Creates a variability table data cell.
    ///
    /// - Parameters:
    ///   - text: The cell text content.
    ///   - alignment: The horizontal content alignment.
    ///   - width: Optional fixed width for the cell.
    /// - Returns: A styled variability table data cell.
    private func variabilityDataCell(_ text: String, alignment: Alignment, width: CGFloat?) -> some View {
        Group {
            if let width {
                Text(text)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)
                    .frame(width: width, alignment: alignment)
                    .frame(minHeight: 22, alignment: alignment)
                    .padding(.horizontal, variabilityTableCellHorizontalPadding)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            } else {
                Text(text)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity, minHeight: 22, alignment: alignment)
                    .padding(.horizontal, variabilityTableCellHorizontalPadding)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            }
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
        locale: Locale,
        localization: WorktimePDFLocalization,
        palette: WorktimeExportColorPalette = .default,
        attributedText: AttributedString = AttributedString("")
    ) {
        self.periodString = periodString
        self.measurements = measurements
        self.locale = locale
        self.localization = localization
        self.palette = palette
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

/// One blood pressure classification bucket used in export distribution.
private enum DistributionCategory: Int, CaseIterable, Identifiable {
    case low
    case optimal
    case normal
    case highNormal
    case hypertensionGrade1
    case hypertensionGrade2
    case hypertensionGrade3

    /// Stable identity for list rendering.
    var id: Int { rawValue }

    /// Returns the localized display title.
    ///
    /// - Parameter localization: The injected localization payload.
    /// - Returns: A localized title for the category.
    func title(localization: WorktimePDFLocalization) -> String {
        switch self {
        case .low:
            localization.categoryLowTitle
        case .optimal:
            localization.categoryOptimalTitle
        case .normal:
            localization.categoryNormalTitle
        case .highNormal:
            localization.categoryHighNormalTitle
        case .hypertensionGrade1:
            localization.categoryHypertensionGrade1Title
        case .hypertensionGrade2:
            localization.categoryHypertensionGrade2Title
        case .hypertensionGrade3:
            localization.categoryHypertensionGrade3Title
        }
    }

    /// Resolves the display color for the category from the injected palette.
    ///
    /// - Parameter palette: The injected export color palette.
    /// - Returns: The category display color.
    func color(in palette: WorktimeExportColorPalette) -> Color {
        switch self {
        case .low:
            palette.low.color
        case .optimal:
            palette.optimal.color
        case .normal:
            palette.normal.color
        case .highNormal:
            palette.highNormal.color
        case .hypertensionGrade1:
            palette.hypertensionGrade1.color
        case .hypertensionGrade2:
            palette.hypertensionGrade2.color
        case .hypertensionGrade3:
            palette.hypertensionGrade3.color
        }
    }

    /// Checks whether one systolic value belongs to this category.
    ///
    /// - Parameter systolic: The systolic blood pressure value.
    /// - Returns: `true` if the value falls into this category.
    func matches(systolic: Int) -> Bool {
        switch self {
        case .low:
            systolic < 105
        case .optimal:
            systolic >= 105 && systolic < 120
        case .normal:
            systolic >= 120 && systolic < 130
        case .highNormal:
            systolic >= 130 && systolic < 140
        case .hypertensionGrade1:
            systolic >= 140 && systolic < 160
        case .hypertensionGrade2:
            systolic >= 160 && systolic < 180
        case .hypertensionGrade3:
            systolic >= 180
        }
    }
}
