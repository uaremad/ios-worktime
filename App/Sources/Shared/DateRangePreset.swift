//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

/// Defines available date-range presets for date filtering.
public enum DateRangePreset: String, CaseIterable, Identifiable {
    /// Shows all measurements without date filtering.
    case all
    /// Shows only measurements from today.
    case today
    /// Shows only measurements from the last 7 days.
    case week
    /// Shows only measurements from the last 30 days.
    case month
    /// Shows only measurements from the current year.
    case year
    /// Shows only measurements from the previous year.
    case lastYear

    /// The stable identity for this preset.
    public var id: String { rawValue }
}
