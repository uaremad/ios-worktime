//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import PDFGenerator

extension ExportPreviewViewModel {
    /// Placeholder localization payload for PDF export.
    var pdfLocalization: WorktimePDFLocalization {
        WorktimePDFLocalization(
            documentTitle: "Export",
            averageValuesTitle: "Durchschnitt",
            individualMeasurementsTitle: "Einträge",
            periodTitle: "Zeitraum",
            dateTitle: "Datum",
            systolicTitle: "Wert A",
            diastolicTitle: "Wert B",
            pulseTitle: "Wert C",
            pulsePressureTitle: "Wert D",
            commentTitle: "Notiz",
            distributionTitle: "Verteilung",
            distributionCategoryTitle: "Kategorie",
            distributionCountTitle: "Anzahl",
            distributionShareTitle: "Anteil",
            variabilityTitle: "Schwankung",
            variabilityValueTitle: "Wert",
            variabilityMeanTitle: "Mittel",
            variabilityMinTitle: "Min",
            variabilityMaxTitle: "Max",
            variabilityRangeTitle: "Spanne",
            variabilityStandardDeviationTitle: "Stdabw",
            groupedMeasurementsTitle: "Einträge",
            noDataTitle: "Keine Daten",
            prevalenceMaximumTitle: "Maximum",
            prevalenceAverageTitle: "Durchschnitt",
            prevalenceTitle: "Häufigkeit",
            prevalenceLast7DaysTitle: "7 Tage",
            prevalenceLast30DaysTitle: "30 Tage",
            prevalenceClassificationHint: "Klassifikation",
            prevalenceNoDataTitle: "Keine Daten",
            prevalenceTargetRangeTitle: "Zielbereich",
            prevalenceElevatedRangeTitle: "Erhöht",
            prevalenceHypertensionRangeTitle: "Hoch",
            prevalenceSummaryPeriodTitle: "Abschnitt",
            prevalenceSummaryTotalTitle: "Gesamt",
            dayPeriodMorningTitle: "Morgen",
            dayPeriodAfternoonTitle: "Nachmittag",
            dayPeriodEveningTitle: "Abend",
            dayPeriodNightTitle: "Nacht",
            categoryLowTitle: "Niedrig",
            categoryOptimalTitle: "Optimal",
            categoryNormalTitle: "Normal",
            categoryHighNormalTitle: "Hoch-normal",
            categoryHypertensionGrade1Title: "Grad 1",
            categoryHypertensionGrade2Title: "Grad 2",
            categoryHypertensionGrade3Title: "Grad 3"
        )
    }
}
