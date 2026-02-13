//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

/// Provides all user-facing strings required by the blood pressure PDF templates.
///
/// PDF rendering happens outside of the app's SwiftUI environment. To ensure correct localization,
/// the app must inject pre-localized strings for the currently selected language.
public struct WorktimePDFLocalization: Sendable {
    /// The primary document title (e.g. "Blood Pressure Values").
    public let documentTitle: String

    /// The section title for average values.
    public let averageValuesTitle: String

    /// The section title for the list of individual measurements.
    public let individualMeasurementsTitle: String

    /// The table header for a date range/period.
    public let periodTitle: String

    /// The table header for a date value.
    public let dateTitle: String

    /// The table header for systolic blood pressure values.
    public let systolicTitle: String

    /// The table header for diastolic blood pressure values.
    public let diastolicTitle: String

    /// The table header for pulse values.
    public let pulseTitle: String

    /// The table header for pulse pressure values.
    public let pulsePressureTitle: String

    /// The table header for a free-text comment.
    public let commentTitle: String

    /// The page title for distribution statistics.
    public let distributionTitle: String

    /// The distribution table header for the category column.
    public let distributionCategoryTitle: String

    /// The distribution table header for the count column.
    public let distributionCountTitle: String

    /// The distribution table header for the percentage/share column.
    public let distributionShareTitle: String

    /// The section title for variability metrics.
    public let variabilityTitle: String

    /// The variability table header for the value/series column.
    public let variabilityValueTitle: String

    /// The variability table header for the mean column.
    public let variabilityMeanTitle: String

    /// The variability table header for the minimum column.
    public let variabilityMinTitle: String

    /// The variability table header for the maximum column.
    public let variabilityMaxTitle: String

    /// The variability table header for the range column.
    public let variabilityRangeTitle: String

    /// The variability table header for the standard deviation column.
    public let variabilityStandardDeviationTitle: String

    /// The title shown on grouped measurement pages.
    public let groupedMeasurementsTitle: String

    /// The placeholder shown when no chart data is available.
    public let noDataTitle: String

    /// The section title for maximum metrics in the prevalence page.
    public let prevalenceMaximumTitle: String

    /// The section title for average metrics in the prevalence page.
    public let prevalenceAverageTitle: String

    /// The prevalence page title.
    public let prevalenceTitle: String

    /// The label for a 7-day prevalence row.
    public let prevalenceLast7DaysTitle: String

    /// The label for a 30-day prevalence row.
    public let prevalenceLast30DaysTitle: String

    /// The hint text describing prevalence classification thresholds.
    public let prevalenceClassificationHint: String

    /// The placeholder shown when prevalence cannot be calculated.
    public let prevalenceNoDataTitle: String

    /// The legend title for values in target range.
    public let prevalenceTargetRangeTitle: String

    /// The legend title for elevated values.
    public let prevalenceElevatedRangeTitle: String

    /// The legend title for high/hypertensive values.
    public let prevalenceHypertensionRangeTitle: String

    /// The summary table header for the day period column.
    public let prevalenceSummaryPeriodTitle: String

    /// The summary row title for the overall period.
    public let prevalenceSummaryTotalTitle: String

    /// The day period title for the morning.
    public let dayPeriodMorningTitle: String

    /// The day period title for the afternoon.
    public let dayPeriodAfternoonTitle: String

    /// The day period title for the evening.
    public let dayPeriodEveningTitle: String

    /// The day period title for the night.
    public let dayPeriodNightTitle: String

    /// The category title for low blood pressure values.
    public let categoryLowTitle: String

    /// The category title for optimal blood pressure values.
    public let categoryOptimalTitle: String

    /// The category title for normal blood pressure values.
    public let categoryNormalTitle: String

    /// The category title for high-normal blood pressure values.
    public let categoryHighNormalTitle: String

    /// The category title for hypertension grade 1.
    public let categoryHypertensionGrade1Title: String

    /// The category title for hypertension grade 2.
    public let categoryHypertensionGrade2Title: String

    /// The category title for hypertension grade 3.
    public let categoryHypertensionGrade3Title: String

    /// Creates a full localization payload for blood pressure PDF rendering.
    public init(
        documentTitle: String,
        averageValuesTitle: String,
        individualMeasurementsTitle: String,
        periodTitle: String,
        dateTitle: String,
        systolicTitle: String,
        diastolicTitle: String,
        pulseTitle: String,
        pulsePressureTitle: String,
        commentTitle: String,
        distributionTitle: String,
        distributionCategoryTitle: String,
        distributionCountTitle: String,
        distributionShareTitle: String,
        variabilityTitle: String,
        variabilityValueTitle: String,
        variabilityMeanTitle: String,
        variabilityMinTitle: String,
        variabilityMaxTitle: String,
        variabilityRangeTitle: String,
        variabilityStandardDeviationTitle: String,
        groupedMeasurementsTitle: String,
        noDataTitle: String,
        prevalenceMaximumTitle: String,
        prevalenceAverageTitle: String,
        prevalenceTitle: String,
        prevalenceLast7DaysTitle: String,
        prevalenceLast30DaysTitle: String,
        prevalenceClassificationHint: String,
        prevalenceNoDataTitle: String,
        prevalenceTargetRangeTitle: String,
        prevalenceElevatedRangeTitle: String,
        prevalenceHypertensionRangeTitle: String,
        prevalenceSummaryPeriodTitle: String,
        prevalenceSummaryTotalTitle: String,
        dayPeriodMorningTitle: String,
        dayPeriodAfternoonTitle: String,
        dayPeriodEveningTitle: String,
        dayPeriodNightTitle: String,
        categoryLowTitle: String,
        categoryOptimalTitle: String,
        categoryNormalTitle: String,
        categoryHighNormalTitle: String,
        categoryHypertensionGrade1Title: String,
        categoryHypertensionGrade2Title: String,
        categoryHypertensionGrade3Title: String
    ) {
        self.documentTitle = documentTitle
        self.averageValuesTitle = averageValuesTitle
        self.individualMeasurementsTitle = individualMeasurementsTitle
        self.periodTitle = periodTitle
        self.dateTitle = dateTitle
        self.systolicTitle = systolicTitle
        self.diastolicTitle = diastolicTitle
        self.pulseTitle = pulseTitle
        self.pulsePressureTitle = pulsePressureTitle
        self.commentTitle = commentTitle
        self.distributionTitle = distributionTitle
        self.distributionCategoryTitle = distributionCategoryTitle
        self.distributionCountTitle = distributionCountTitle
        self.distributionShareTitle = distributionShareTitle
        self.variabilityTitle = variabilityTitle
        self.variabilityValueTitle = variabilityValueTitle
        self.variabilityMeanTitle = variabilityMeanTitle
        self.variabilityMinTitle = variabilityMinTitle
        self.variabilityMaxTitle = variabilityMaxTitle
        self.variabilityRangeTitle = variabilityRangeTitle
        self.variabilityStandardDeviationTitle = variabilityStandardDeviationTitle
        self.groupedMeasurementsTitle = groupedMeasurementsTitle
        self.noDataTitle = noDataTitle
        self.prevalenceMaximumTitle = prevalenceMaximumTitle
        self.prevalenceAverageTitle = prevalenceAverageTitle
        self.prevalenceTitle = prevalenceTitle
        self.prevalenceLast7DaysTitle = prevalenceLast7DaysTitle
        self.prevalenceLast30DaysTitle = prevalenceLast30DaysTitle
        self.prevalenceClassificationHint = prevalenceClassificationHint
        self.prevalenceNoDataTitle = prevalenceNoDataTitle
        self.prevalenceTargetRangeTitle = prevalenceTargetRangeTitle
        self.prevalenceElevatedRangeTitle = prevalenceElevatedRangeTitle
        self.prevalenceHypertensionRangeTitle = prevalenceHypertensionRangeTitle
        self.prevalenceSummaryPeriodTitle = prevalenceSummaryPeriodTitle
        self.prevalenceSummaryTotalTitle = prevalenceSummaryTotalTitle
        self.dayPeriodMorningTitle = dayPeriodMorningTitle
        self.dayPeriodAfternoonTitle = dayPeriodAfternoonTitle
        self.dayPeriodEveningTitle = dayPeriodEveningTitle
        self.dayPeriodNightTitle = dayPeriodNightTitle
        self.categoryLowTitle = categoryLowTitle
        self.categoryOptimalTitle = categoryOptimalTitle
        self.categoryNormalTitle = categoryNormalTitle
        self.categoryHighNormalTitle = categoryHighNormalTitle
        self.categoryHypertensionGrade1Title = categoryHypertensionGrade1Title
        self.categoryHypertensionGrade2Title = categoryHypertensionGrade2Title
        self.categoryHypertensionGrade3Title = categoryHypertensionGrade3Title
    }
}
