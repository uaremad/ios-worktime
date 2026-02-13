//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import SwiftUI

/// A PDF page template showing grouped day ranges with lower/upper dots and connecting lines.
public struct WorktimeGroupedChartTemplate: TemplateProtocol {
    /// Mutable attributed text payload required by `TemplateProtocol`.
    public var attributedText: AttributedString

    /// The period string displayed below the page title.
    let periodString: String

    /// The measurements used to compute grouped daily ranges.
    let measurements: [MeasurementData]

    /// Indicates whether pulse pressure should be rendered.
    let includePulsePressure: Bool

    /// The injected export color palette.
    let palette: WorktimeExportColorPalette

    /// The locale used for localized date formatting.
    let locale: Locale

    /// The injected localization used for all user-facing strings.
    let localization: WorktimePDFLocalization

    public var body: some View {
        let groupedRanges = groupedDailyRanges()
        let panelHeight: CGFloat = 130
        let chartAccentColor = palette.accent.color

        return VStack(alignment: .leading, spacing: 14) {
            Text(localization.groupedMeasurementsTitle)
                .font(.system(size: 24, weight: .bold))

            Text(periodString)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)

            RangePanelView(
                title: localization.systolicTitle,
                titleColor: chartAccentColor,
                ranges: groupedRanges.map { .init(date: $0.date, lower: $0.lowerSystolic, upper: $0.upperSystolic) },
                panelHeight: panelHeight,
                locale: locale,
                noDataTitle: localization.noDataTitle
            )

            RangePanelView(
                title: localization.diastolicTitle,
                titleColor: chartAccentColor,
                ranges: groupedRanges.map { .init(date: $0.date, lower: $0.lowerDiastolic, upper: $0.upperDiastolic) },
                panelHeight: panelHeight,
                locale: locale,
                noDataTitle: localization.noDataTitle
            )

            RangePanelView(
                title: localization.pulseTitle,
                titleColor: chartAccentColor,
                ranges: groupedRanges.map { .init(date: $0.date, lower: $0.lowerPulse, upper: $0.upperPulse) },
                panelHeight: panelHeight,
                locale: locale,
                noDataTitle: localization.noDataTitle
            )

            if includePulsePressure {
                RangePanelView(
                    title: localization.pulsePressureTitle,
                    titleColor: chartAccentColor,
                    ranges: groupedRanges.map { .init(date: $0.date, lower: $0.lowerPulsePressure, upper: $0.upperPulsePressure) },
                    panelHeight: panelHeight,
                    locale: locale,
                    noDataTitle: localization.noDataTitle
                )
            }

            Spacer(minLength: 0)
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Groups measurements by day and computes lower/upper bounds per metric.
    ///
    /// - Returns: Sorted grouped daily ranges.
    private func groupedDailyRanges() -> [GroupedDayRange] {
        let grouped = Dictionary(grouping: measurements) { measurement in
            Calendar.current.startOfDay(for: measurement.date)
        }

        return grouped.keys.sorted().compactMap { day in
            guard let dayMeasurements = grouped[day], dayMeasurements.isEmpty == false else {
                return nil
            }

            let systolicValues = dayMeasurements.map(\.systolic)
            let diastolicValues = dayMeasurements.map(\.diastolic)
            let pulseValues = dayMeasurements.map(\.pulse)
            let pulsePressureValues = dayMeasurements.map { max(0, $0.systolic - $0.diastolic) }

            guard
                let lowerSystolic = systolicValues.min(),
                let upperSystolic = systolicValues.max(),
                let lowerDiastolic = diastolicValues.min(),
                let upperDiastolic = diastolicValues.max(),
                let lowerPulse = pulseValues.min(),
                let upperPulse = pulseValues.max(),
                let lowerPulsePressure = pulsePressureValues.min(),
                let upperPulsePressure = pulsePressureValues.max()
            else {
                return nil
            }

            return GroupedDayRange(
                date: day,
                lowerSystolic: lowerSystolic,
                upperSystolic: upperSystolic,
                lowerDiastolic: lowerDiastolic,
                upperDiastolic: upperDiastolic,
                lowerPulse: lowerPulse,
                upperPulse: upperPulse,
                lowerPulsePressure: lowerPulsePressure,
                upperPulsePressure: upperPulsePressure
            )
        }
    }

    public init(
        periodString: String,
        measurements: [MeasurementData],
        includePulsePressure: Bool,
        locale: Locale,
        localization: WorktimePDFLocalization,
        palette: WorktimeExportColorPalette = .default,
        attributedText: AttributedString = AttributedString("")
    ) {
        self.periodString = periodString
        self.measurements = measurements
        self.includePulsePressure = includePulsePressure
        self.locale = locale
        self.localization = localization
        self.palette = palette
        self.attributedText = attributedText
    }
}

/// Renders one grouped range panel for a single metric.
private struct RangePanelView: View {
    /// The panel title.
    let title: String
    /// The accent color used for lines and markers.
    let titleColor: Color
    /// The grouped ranges shown in this panel.
    let ranges: [MetricRangePoint]
    /// Fixed panel height to keep all chart panels equal.
    let panelHeight: CGFloat
    /// The locale used for localized date formatting.
    let locale: Locale
    /// The placeholder shown when no data is available.
    let noDataTitle: String

    var body: some View {
        let renderedRanges = ranges

        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(titleColor)

            if renderedRanges.isEmpty {
                Text(noDataTitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: panelHeight, alignment: .center)
                    .background(Color.gray.opacity(0.08))
            } else {
                GeometryReader { proxy in
                    let chartHeight = max(80, proxy.size.height - 20)
                    let yBounds = yBounds(ranges: renderedRanges)

                    ZStack(alignment: .topLeading) {
                        chartGrid(size: CGSize(width: proxy.size.width, height: chartHeight), points: renderedRanges)
                        rangeSeries(
                            size: CGSize(width: proxy.size.width, height: chartHeight),
                            bounds: yBounds,
                            points: renderedRanges
                        )
                        axisLabels(size: CGSize(width: proxy.size.width, height: chartHeight), bounds: yBounds)
                    }
                    .frame(height: chartHeight)

                    dateLabels(width: proxy.size.width, points: renderedRanges)
                        .padding(.top, chartHeight + 2)
                }
                .frame(height: panelHeight)
            }
        }
    }

    /// Draws a lightweight grid in the chart area.
    ///
    /// - Parameters:
    ///   - size: The drawing size.
    ///   - points: The rendered points.
    /// - Returns: The grid view.
    private func chartGrid(size: CGSize, points: [MetricRangePoint]) -> some View {
        ZStack {
            ForEach(0 ..< 5, id: \.self) { index in
                let y = size.height * CGFloat(index) / 4
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                .stroke(Color.gray.opacity(0.25), lineWidth: 0.7)
            }

            ForEach(Array(points.enumerated()), id: \.offset) { index, _ in
                let x = xPosition(for: index, totalCount: points.count, width: size.width)
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                .stroke(Color.gray.opacity(0.18), lineWidth: 0.7)
            }
        }
    }

    /// Draws lower/upper dots connected by one vertical line per day.
    ///
    /// - Parameters:
    ///   - size: The drawing size.
    ///   - bounds: The Y-axis bounds.
    ///   - points: The rendered points.
    /// - Returns: The rendered series layer.
    private func rangeSeries(
        size: CGSize,
        bounds: (min: Double, max: Double),
        points: [MetricRangePoint]
    ) -> some View {
        ZStack {
            ForEach(Array(points.enumerated()), id: \.offset) { index, range in
                let x = xPosition(for: index, totalCount: points.count, width: size.width)
                let lowerY = yPosition(for: Double(range.lower), height: size.height, minValue: bounds.min, maxValue: bounds.max)
                let upperY = yPosition(for: Double(range.upper), height: size.height, minValue: bounds.min, maxValue: bounds.max)

                Path { path in
                    path.move(to: CGPoint(x: x, y: upperY))
                    path.addLine(to: CGPoint(x: x, y: lowerY))
                }
                .stroke(titleColor.opacity(0.75), lineWidth: 1.8)

                Circle()
                    .fill(titleColor)
                    .frame(width: 4.5, height: 4.5)
                    .position(x: x, y: upperY)

                Circle()
                    .fill(titleColor)
                    .frame(width: 4.5, height: 4.5)
                    .position(x: x, y: lowerY)
            }
        }
    }

    /// Draws min/max axis labels on the left side.
    ///
    /// - Parameters:
    ///   - size: The drawing size.
    ///   - bounds: The Y-axis bounds.
    /// - Returns: The axis label layer.
    private func axisLabels(size: CGSize, bounds: (min: Double, max: Double)) -> some View {
        ZStack(alignment: .leading) {
            Text("\(Int(bounds.max.rounded()))")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
                .position(x: 14, y: 8)

            Text("\(Int(bounds.min.rounded()))")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
                .position(x: 14, y: size.height - 8)
        }
    }

    /// Draws a compact date label row for the X-axis.
    ///
    /// - Parameters:
    ///   - width: The available chart width.
    ///   - points: The rendered points.
    /// - Returns: The label row.
    private func dateLabels(width: CGFloat, points: [MetricRangePoint]) -> some View {
        let labelIndices = relevantLabelIndices(count: points.count)
        return ZStack(alignment: .leading) {
            ForEach(labelIndices, id: \.self) { index in
                let x = xPosition(for: index, totalCount: points.count, width: width)
                Text(points[index].date.formatted(
                    .dateTime
                        .day()
                        .month(.twoDigits)
                        .locale(locale)
                ))
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
                .position(x: x, y: 8)
            }
        }
        .frame(height: 16)
    }

    /// Computes compact Y-axis bounds for one panel.
    ///
    /// - Parameter ranges: The rendered points.
    /// - Returns: Min and max bounds with small padding.
    private func yBounds(ranges: [MetricRangePoint]) -> (min: Double, max: Double) {
        let allValues = ranges.flatMap { [Double($0.lower), Double($0.upper)] }
        let minValue = (allValues.min() ?? 0) - 4
        let maxValue = (allValues.max() ?? 100) + 4
        if maxValue <= minValue {
            return (min: minValue, max: minValue + 10)
        }
        return (min: minValue, max: maxValue)
    }

    /// Computes the X-position for one grouped data index.
    ///
    /// - Parameters:
    ///   - index: The zero-based index.
    ///   - totalCount: The number of points.
    ///   - width: The chart width.
    /// - Returns: The horizontal position.
    private func xPosition(for index: Int, totalCount: Int, width: CGFloat) -> CGFloat {
        guard totalCount > 1 else { return width - 12 }
        return CGFloat(index) * (width - 24) / CGFloat(totalCount - 1) + 12
    }

    /// Computes the Y-position for one value.
    ///
    /// - Parameters:
    ///   - value: The metric value.
    ///   - height: The chart height.
    ///   - minValue: The lower axis bound.
    ///   - maxValue: The upper axis bound.
    /// - Returns: The vertical position in chart coordinates.
    private func yPosition(for value: Double, height: CGFloat, minValue: Double, maxValue: Double) -> CGFloat {
        guard maxValue > minValue else { return height / 2 }
        let ratio = (value - minValue) / (maxValue - minValue)
        return (height - 8) * CGFloat(1 - ratio) + 4
    }

    /// Selects X-axis label indices in a fixed 5-day interval.
    ///
    /// - Parameter count: Total number of points.
    /// - Returns: Sorted indices for every fifth day plus the last day.
    private func relevantLabelIndices(count: Int) -> [Int] {
        guard count > 0 else { return [] }
        if count <= 5 { return Array(0 ..< count) }

        let step = 5
        var indices = stride(from: 0, to: count, by: step).map(\.self)
        if let lastIndex = indices.last, lastIndex != count - 1 {
            indices.append(count - 1)
        }
        return indices
    }
}

/// One metric range point for a single day.
private struct MetricRangePoint: Identifiable {
    /// Stable identity derived from day timestamp.
    var id: Date { date }
    /// The grouped day.
    let date: Date
    /// The lower bound for the day.
    let lower: Int
    /// The upper bound for the day.
    let upper: Int
}

/// One grouped day range used to prepare chart panels.
private struct GroupedDayRange {
    /// The grouped day.
    let date: Date
    /// Systolic lower bound.
    let lowerSystolic: Int
    /// Systolic upper bound.
    let upperSystolic: Int
    /// Diastolic lower bound.
    let lowerDiastolic: Int
    /// Diastolic upper bound.
    let upperDiastolic: Int
    /// Pulse lower bound.
    let lowerPulse: Int
    /// Pulse upper bound.
    let upperPulse: Int
    /// Pulse pressure lower bound.
    let lowerPulsePressure: Int
    /// Pulse pressure upper bound.
    let upperPulsePressure: Int
}
