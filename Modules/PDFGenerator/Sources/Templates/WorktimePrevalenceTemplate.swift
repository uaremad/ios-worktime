//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import SwiftUI

/// A PDF page template showing prevalence distributions for 7 and 30 days.
public struct WorktimePrevalenceTemplate: TemplateProtocol {
    /// Mutable attributed text payload required by `TemplateProtocol`.
    public var attributedText: AttributedString

    /// The period string displayed below the page title.
    let periodString: String

    /// The localized page header shown above prevalence content.
    let headerTitle: String

    /// The measurements used to calculate prevalence.
    let measurements: [MeasurementData]

    /// The injected export color palette.
    let palette: WorktimeExportColorPalette

    /// Indicates whether print mode is black-and-white.
    let useBlackAndWhitePrint: Bool

    /// The locale used for localized date and number formatting.
    let locale: Locale

    /// The injected localization used for all user-facing strings.
    let localization: WorktimePDFLocalization

    /// Shared horizontal padding used by summary table cells.
    private let tableCellHorizontalPadding: CGFloat = 6

    /// Creates a prevalence page template.
    ///
    /// - Parameters:
    ///   - periodString: The period string displayed below the page title.
    ///   - headerTitle: The page header title.
    ///   - measurements: The measurements used to calculate prevalence.
    ///   - locale: The locale used for localized date and number formatting.
    ///   - localization: The localization used for all user-facing strings.
    ///   - palette: The export color palette used for rendering.
    ///   - useBlackAndWhitePrint: Indicates whether print mode should be black-and-white.
    ///   - attributedText: The attributed text payload required by `TemplateProtocol`.
    public init(
        periodString: String,
        headerTitle: String,
        measurements: [MeasurementData],
        locale: Locale,
        localization: WorktimePDFLocalization,
        palette: WorktimeExportColorPalette = .default,
        useBlackAndWhitePrint: Bool = false,
        attributedText: AttributedString = AttributedString("")
    ) {
        self.periodString = periodString
        self.headerTitle = headerTitle
        self.measurements = measurements
        self.locale = locale
        self.localization = localization
        self.palette = palette
        self.useBlackAndWhitePrint = useBlackAndWhitePrint
        self.attributedText = attributedText
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(headerTitle)
                .font(.system(size: 24, weight: .bold))

            Text(periodString)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)

            Rectangle()
                .fill(headerDividerColor)
                .frame(height: 2)

            summarySection(
                title: localization.prevalenceMaximumTitle,
                rows: summaryRows { maximumMetrics(for: $0) }
            )

            summarySection(
                title: localization.prevalenceAverageTitle,
                rows: summaryRows { averageMetrics(for: $0) }
            )

            Text(localization.prevalenceTitle)
                .font(.system(size: 20, weight: .bold))

            if let distribution7Days, let distribution30Days {
                prevalenceRow(
                    title: localization.prevalenceLast7DaysTitle,
                    distribution: distribution7Days
                )

                prevalenceRow(
                    title: localization.prevalenceLast30DaysTitle,
                    distribution: distribution30Days
                )

                legend

                Text(localization.prevalenceClassificationHint)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.secondary)
            } else {
                Text(localization.prevalenceNoDataTitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension WorktimePrevalenceTemplate {
    /// Builds one compact summary section with title and metrics table.
    ///
    /// - Parameters:
    ///   - title: The section title.
    ///   - rows: The row payload displayed in the table.
    /// - Returns: A summary section view.
    private func summarySection(title: String, rows: [PressureSummaryRow]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)

            summaryTable(rows: rows)
        }
    }

    /// Builds one compact summary table.
    ///
    /// - Parameter rows: The table rows to render.
    /// - Returns: A summary table view.
    private func summaryTable(rows: [PressureSummaryRow]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                summaryHeaderCell(localization.prevalenceSummaryPeriodTitle, alignment: .leading, width: nil)
                summaryHeaderCell(localization.systolicTitle, alignment: .center, width: 80)
                summaryHeaderCell(localization.diastolicTitle, alignment: .center, width: 80)
                summaryHeaderCell(localization.pulseTitle, alignment: .center, width: 80)
            }
            .background(Color.gray.opacity(0.15))

            ForEach(rows) { row in
                HStack(spacing: 0) {
                    summaryDataCell(row.title, alignment: .leading, width: nil)
                    summaryDataCell("\(row.systolic)", alignment: .center, width: 80)
                    summaryDataCell("\(row.diastolic)", alignment: .center, width: 80)
                    summaryDataCell("\(row.pulse)", alignment: .center, width: 80)
                }
            }
        }
        .border(Color.gray.opacity(0.45), width: 1)
    }

    /// Creates one header cell for the summary table.
    ///
    /// - Parameters:
    ///   - text: The header label.
    ///   - alignment: The text alignment.
    ///   - width: Optional fixed column width.
    /// - Returns: A styled header cell.
    private func summaryHeaderCell(_ text: String, alignment: Alignment, width: CGFloat?) -> some View {
        Group {
            if let width {
                Text(text)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: width, alignment: alignment)
                    .frame(minHeight: 24, alignment: alignment)
                    .padding(.horizontal, tableCellHorizontalPadding)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            } else {
                Text(text)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, minHeight: 24, alignment: alignment)
                    .padding(.horizontal, tableCellHorizontalPadding)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            }
        }
    }

    /// Creates one data cell for the summary table.
    ///
    /// - Parameters:
    ///   - text: The cell text.
    ///   - alignment: The text alignment.
    ///   - width: Optional fixed column width.
    /// - Returns: A styled data cell.
    private func summaryDataCell(_ text: String, alignment: Alignment, width: CGFloat?) -> some View {
        Group {
            if let width {
                Text(text)
                    .font(.system(size: 10, weight: .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: width, alignment: alignment)
                    .frame(minHeight: 22, alignment: alignment)
                    .padding(.horizontal, tableCellHorizontalPadding)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            } else {
                Text(text)
                    .font(.system(size: 10, weight: .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, minHeight: 22, alignment: alignment)
                    .padding(.horizontal, tableCellHorizontalPadding)
                    .border(Color.gray.opacity(0.3), width: 0.5)
            }
        }
    }

    /// The prevalence distribution for the last 7 days.
    private var distribution7Days: PrevalenceDistribution? {
        distribution(forLastDays: 7)
    }

    /// The prevalence distribution for the last 30 days.
    private var distribution30Days: PrevalenceDistribution? {
        distribution(forLastDays: 30)
    }

    /// Creates one full-width horizontal stacked prevalence row.
    ///
    /// - Parameters:
    ///   - title: The row title.
    ///   - distribution: The prevalence distribution for this row.
    /// - Returns: A full-width prevalence row view.
    private func prevalenceRow(
        title: String,
        distribution: PrevalenceDistribution
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)

            GeometryReader { proxy in
                let totalWidth = proxy.size.width
                HStack(spacing: 0) {
                    prevalenceSegment(
                        color: palette.accent.color.opacity(0.3),
                        width: width(for: distribution.targetCount, totalCount: distribution.totalCount, totalWidth: totalWidth),
                        percentage: distribution.targetPercentage
                    )
                    prevalenceSegment(
                        color: palette.accent.color.opacity(0.6),
                        width: width(for: distribution.elevatedCount, totalCount: distribution.totalCount, totalWidth: totalWidth),
                        percentage: distribution.elevatedPercentage
                    )
                    prevalenceSegment(
                        color: palette.accent.color.opacity(0.9),
                        width: width(for: distribution.hypertensionCount, totalCount: distribution.totalCount, totalWidth: totalWidth),
                        percentage: distribution.hypertensionPercentage
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.08))
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(height: 30)
        }
    }

    /// Creates one stacked segment with optional percentage text.
    ///
    /// - Parameters:
    ///   - color: The segment color.
    ///   - width: The absolute segment width.
    ///   - percentage: The rounded percentage label.
    /// - Returns: A prevalence segment view.
    private func prevalenceSegment(
        color: Color,
        width: CGFloat,
        percentage: Int
    ) -> some View {
        ZStack {
            Rectangle()
                .fill(color)

            if percentage >= 8 {
                Text("\(percentage)%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: max(1, width), height: 30)
    }

    /// Creates the legend for the prevalence chart segments.
    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(
                title: localization.prevalenceTargetRangeTitle,
                color: palette.accent.color.opacity(0.3)
            )
            legendItem(
                title: localization.prevalenceElevatedRangeTitle,
                color: palette.accent.color.opacity(0.6)
            )
            legendItem(
                title: localization.prevalenceHypertensionRangeTitle,
                color: palette.accent.color.opacity(0.9)
            )
        }
    }

    /// Creates one legend item.
    ///
    /// - Parameters:
    ///   - title: The legend label.
    ///   - color: The legend color marker.
    /// - Returns: A legend item view.
    private func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 9, height: 9)
            Text(title)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.primary)
        }
    }

    /// Calculates one prevalence distribution for the last N days.
    ///
    /// - Parameter days: The number of trailing days.
    /// - Returns: The resulting prevalence distribution.
    private func distribution(forLastDays days: Int) -> PrevalenceDistribution? {
        guard let latestDate = measurements.map(\.date).max() else {
            return nil
        }

        let calendar = Calendar.current
        let thresholdDate = calendar.date(byAdding: .day, value: -(days - 1), to: latestDate) ?? latestDate
        let filtered = measurements.filter { $0.date >= thresholdDate }
        guard filtered.isEmpty == false else {
            return nil
        }

        let targetCount = filtered.filter { $0.systolic <= 129 }.count
        let elevatedCount = filtered.filter { (130 ... 139).contains($0.systolic) }.count
        let hypertensionCount = filtered.filter { $0.systolic >= 140 }.count

        return PrevalenceDistribution(
            targetCount: targetCount,
            elevatedCount: elevatedCount,
            hypertensionCount: hypertensionCount
        )
    }

    /// Calculates absolute width for one segment based on count ratio.
    ///
    /// - Parameters:
    ///   - count: The segment count.
    ///   - totalCount: The total distribution count.
    ///   - totalWidth: The available row width.
    /// - Returns: The absolute width for the segment.
    private func width(for count: Int, totalCount: Int, totalWidth: CGFloat) -> CGFloat {
        guard totalCount > 0 else { return 0 }
        return totalWidth * CGFloat(count) / CGFloat(totalCount)
    }

    /// Builds ordered summary rows for all day periods and total.
    ///
    /// - Parameter metrics: Closure calculating metrics for one day period.
    /// - Returns: Ordered table rows with fallback zero-values.
    private func summaryRows(
        metrics: (DayPeriod?) -> PressureMetrics?
    ) -> [PressureSummaryRow] {
        let periodRows = DayPeriod.allCases.map { period -> PressureSummaryRow in
            let values = metrics(period) ?? PressureMetrics(systolic: 0, diastolic: 0, pulse: 0)
            return PressureSummaryRow(
                title: period.title(localization: localization),
                systolic: values.systolic,
                diastolic: values.diastolic,
                pulse: values.pulse
            )
        }

        let totalValues = metrics(nil) ?? PressureMetrics(systolic: 0, diastolic: 0, pulse: 0)
        let totalRow = PressureSummaryRow(
            title: localization.prevalenceSummaryTotalTitle,
            systolic: totalValues.systolic,
            diastolic: totalValues.diastolic,
            pulse: totalValues.pulse
        )

        return periodRows + [totalRow]
    }

    /// Calculates maximum pressure metrics for one period or for all measurements.
    ///
    /// - Parameter period: Optional day period filter.
    /// - Returns: Maximum metrics if measurements are available.
    private func maximumMetrics(for period: DayPeriod?) -> PressureMetrics? {
        let filtered = filteredMeasurements(for: period)
        guard filtered.isEmpty == false else { return nil }

        return PressureMetrics(
            systolic: filtered.map(\.systolic).max() ?? 0,
            diastolic: filtered.map(\.diastolic).max() ?? 0,
            pulse: filtered.map(\.pulse).max() ?? 0
        )
    }

    /// Calculates average pressure metrics for one period or for all measurements.
    ///
    /// - Parameter period: Optional day period filter.
    /// - Returns: Rounded average metrics if measurements are available.
    private func averageMetrics(for period: DayPeriod?) -> PressureMetrics? {
        let filtered = filteredMeasurements(for: period)
        guard filtered.isEmpty == false else { return nil }

        let count = Double(filtered.count)
        let systolicAverage = Int((filtered.map { Double($0.systolic) }.reduce(0, +) / count).rounded())
        let diastolicAverage = Int((filtered.map { Double($0.diastolic) }.reduce(0, +) / count).rounded())
        let pulseAverage = Int((filtered.map { Double($0.pulse) }.reduce(0, +) / count).rounded())

        return PressureMetrics(
            systolic: systolicAverage,
            diastolic: diastolicAverage,
            pulse: pulseAverage
        )
    }

    /// Filters measurements for one period, or returns all when no period is passed.
    ///
    /// - Parameter period: Optional day period filter.
    /// - Returns: Matching measurements.
    private func filteredMeasurements(for period: DayPeriod?) -> [MeasurementData] {
        guard let period else { return measurements }
        let calendar = Calendar.current

        return measurements.filter { measurement in
            let hour = calendar.component(.hour, from: measurement.date)
            return period.contains(hour: hour)
        }
    }

    /// The divider color below the header section.
    private var headerDividerColor: Color {
        useBlackAndWhitePrint ? Color.black.opacity(0.55) : palette.accent.color
    }
}

/// Stores one compact pressure metric triple.
private struct PressureMetrics {
    /// The systolic pressure value.
    let systolic: Int

    /// The diastolic pressure value.
    let diastolic: Int

    /// The pulse value.
    let pulse: Int
}

/// Stores one row used by summary pressure tables.
private struct PressureSummaryRow: Identifiable {
    /// Stable row identity.
    let id = UUID()

    /// The row title.
    let title: String

    /// The systolic value.
    let systolic: Int

    /// The diastolic value.
    let diastolic: Int

    /// The pulse value.
    let pulse: Int
}

/// Defines time-of-day buckets for summary table grouping.
private enum DayPeriod: CaseIterable {
    case morning
    case afternoon
    case evening
    case night

    /// Returns the localized display title shown in the summary table.
    ///
    /// - Parameter localization: The injected localization payload.
    /// - Returns: A localized title for the period.
    func title(localization: WorktimePDFLocalization) -> String {
        switch self {
        case .morning:
            localization.dayPeriodMorningTitle
        case .afternoon:
            localization.dayPeriodAfternoonTitle
        case .evening:
            localization.dayPeriodEveningTitle
        case .night:
            localization.dayPeriodNightTitle
        }
    }

    /// Checks whether one hour belongs to the period.
    ///
    /// - Parameter hour: The 24h hour component.
    /// - Returns: `true` when the hour is in this period.
    func contains(hour: Int) -> Bool {
        switch self {
        case .night:
            hour >= 0 && hour < 6
        case .morning:
            hour >= 6 && hour < 12
        case .afternoon:
            hour >= 12 && hour < 18
        case .evening:
            hour >= 18 && hour < 24
        }
    }
}

/// Stores prevalence counts and derived percentages for one period.
private struct PrevalenceDistribution {
    /// The number of values in target range (`<=129`).
    let targetCount: Int

    /// The number of values in elevated range (`130...139`).
    let elevatedCount: Int

    /// The number of values in hypertension range (`>=140`).
    let hypertensionCount: Int

    /// The total number of values.
    var totalCount: Int {
        targetCount + elevatedCount + hypertensionCount
    }

    /// The rounded target percentage.
    var targetPercentage: Int {
        percentage(for: targetCount)
    }

    /// The rounded elevated percentage.
    var elevatedPercentage: Int {
        percentage(for: elevatedCount)
    }

    /// The rounded hypertension percentage.
    var hypertensionPercentage: Int {
        percentage(for: hypertensionCount)
    }

    /// Converts one count to a rounded percentage.
    ///
    /// - Parameter count: The source count.
    /// - Returns: The rounded percentage value.
    private func percentage(for count: Int) -> Int {
        guard totalCount > 0 else { return 0 }
        return Int((Double(count) / Double(totalCount) * 100).rounded())
    }
}
