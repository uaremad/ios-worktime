//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import SwiftUI

public enum PDFTemplate: String, CaseIterable {
    case blank
    case worktimeExport

    public func view(_ attributedText: AttributedString = AttributedString("")) -> any TemplateProtocol {
        switch self {
        case .blank:
            BlankPage(attributedText)
        case .worktimeExport:
            WorktimeExportTemplate(
                title: "",
                periodString: "",
                measurements: [],
                includeComments: false,
                includePulsePressure: false,
                locale: Locale.current,
                localization: Self.fallbackLocalization,
                attributedText: attributedText
            )
        }
    }

    private static var fallbackLocalization: WorktimePDFLocalization {
        WorktimePDFLocalization(
            documentTitle: "Blood Pressure Values",
            averageValuesTitle: "Average Values",
            individualMeasurementsTitle: "Measurements",
            periodTitle: "Period",
            dateTitle: "Date",
            systolicTitle: "Systolic",
            diastolicTitle: "Diastolic",
            pulseTitle: "Pulse",
            pulsePressureTitle: "Pulse Pressure",
            commentTitle: "Comment",
            distributionTitle: "Distribution",
            distributionCategoryTitle: "Category",
            distributionCountTitle: "Count",
            distributionShareTitle: "Share",
            variabilityTitle: "Variability",
            variabilityValueTitle: "Value",
            variabilityMeanTitle: "Mean",
            variabilityMinTitle: "Min",
            variabilityMaxTitle: "Max",
            variabilityRangeTitle: "Range",
            variabilityStandardDeviationTitle: "Std. Dev.",
            groupedMeasurementsTitle: "Measurements",
            noDataTitle: "No data",
            prevalenceMaximumTitle: "Maximum Blood Pressure",
            prevalenceAverageTitle: "Average Blood Pressure",
            prevalenceTitle: "Prevalence",
            prevalenceLast7DaysTitle: "Last 7 Days",
            prevalenceLast30DaysTitle: "Last 30 Days",
            prevalenceClassificationHint: "Classification by systolic values.",
            prevalenceNoDataTitle: "No data available.",
            prevalenceTargetRangeTitle: "In target range",
            prevalenceElevatedRangeTitle: "Elevated",
            prevalenceHypertensionRangeTitle: "High",
            prevalenceSummaryPeriodTitle: "Period",
            prevalenceSummaryTotalTitle: "Total",
            dayPeriodMorningTitle: "Morning",
            dayPeriodAfternoonTitle: "Afternoon",
            dayPeriodEveningTitle: "Evening",
            dayPeriodNightTitle: "Night",
            categoryLowTitle: "Low",
            categoryOptimalTitle: "Optimal",
            categoryNormalTitle: "Normal",
            categoryHighNormalTitle: "High Normal",
            categoryHypertensionGrade1Title: "Hypertension Grade 1",
            categoryHypertensionGrade2Title: "Hypertension Grade 2",
            categoryHypertensionGrade3Title: "Hypertension Grade 3"
        )
    }
}
