//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

/// A static RGB color used by PDF templates.
public struct PDFTemplateColor: Sendable {
    /// The red channel in range `0...1`.
    public let red: Double

    /// The green channel in range `0...1`.
    public let green: Double

    /// The blue channel in range `0...1`.
    public let blue: Double

    /// Converts the stored RGB channels to a SwiftUI color.
    public var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    /// Creates one static PDF color.
    ///
    /// - Parameters:
    ///   - red: The red channel in range `0...1`.
    ///   - green: The green channel in range `0...1`.
    ///   - blue: The blue channel in range `0...1`.
    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

/// Shared palette used by blood pressure PDF export templates.
public struct WorktimeExportColorPalette: Sendable {
    /// The accent color used by grouped chart panels.
    public let accent: PDFTemplateColor

    /// The classification color for low pressure values.
    public let low: PDFTemplateColor

    /// The classification color for optimal pressure values.
    public let optimal: PDFTemplateColor

    /// The classification color for normal pressure values.
    public let normal: PDFTemplateColor

    /// The classification color for high-normal pressure values.
    public let highNormal: PDFTemplateColor

    /// The classification color for hypertension grade 1.
    public let hypertensionGrade1: PDFTemplateColor

    /// The classification color for hypertension grade 2.
    public let hypertensionGrade2: PDFTemplateColor

    /// The classification color for hypertension grade 3.
    public let hypertensionGrade3: PDFTemplateColor

    /// Creates one shared export palette.
    ///
    /// - Parameters:
    ///   - accent: The accent color for grouped chart panels.
    ///   - low: The classification color for low values.
    ///   - optimal: The classification color for optimal values.
    ///   - normal: The classification color for normal values.
    ///   - highNormal: The classification color for high-normal values.
    ///   - hypertensionGrade1: The classification color for grade 1 hypertension.
    ///   - hypertensionGrade2: The classification color for grade 2 hypertension.
    ///   - hypertensionGrade3: The classification color for grade 3 hypertension.
    public init(
        accent: PDFTemplateColor,
        low: PDFTemplateColor,
        optimal: PDFTemplateColor,
        normal: PDFTemplateColor,
        highNormal: PDFTemplateColor,
        hypertensionGrade1: PDFTemplateColor,
        hypertensionGrade2: PDFTemplateColor,
        hypertensionGrade3: PDFTemplateColor
    ) {
        self.accent = accent
        self.low = low
        self.optimal = optimal
        self.normal = normal
        self.highNormal = highNormal
        self.hypertensionGrade1 = hypertensionGrade1
        self.hypertensionGrade2 = hypertensionGrade2
        self.hypertensionGrade3 = hypertensionGrade3
    }
}

public extension WorktimeExportColorPalette {
    /// The legacy fallback palette used when no app-specific colors are injected.
    static let `default` = WorktimeExportColorPalette(
        accent: PDFTemplateColor(red: 0.0, green: 0.478, blue: 1.0),
        low: PDFTemplateColor(red: 0.196, green: 0.333, blue: 0.627),
        optimal: PDFTemplateColor(red: 0.027, green: 0.471, blue: 0.027),
        normal: PDFTemplateColor(red: 0.0, green: 0.804, blue: 0.0),
        highNormal: PDFTemplateColor(red: 0.902, green: 0.820, blue: 0.267),
        hypertensionGrade1: PDFTemplateColor(red: 1.0, green: 0.576, blue: 0.231),
        hypertensionGrade2: PDFTemplateColor(red: 0.863, green: 0.078, blue: 0.078),
        hypertensionGrade3: PDFTemplateColor(red: 0.455, green: 0.173, blue: 0.173)
    )
}
