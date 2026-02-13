//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

/// Defines shared behavior for string-backed Core Data enums.
public protocol CoreDataStringEnum: RawRepresentable, CaseIterable, Codable, Hashable, Sendable where RawValue == String {}

public extension CoreDataStringEnum {
    /// Initializes the enum from an optional Core Data string value.
    ///
    /// - Parameter coreDataValue: The persisted string value.
    init?(coreDataValue: String?) {
        guard let value = coreDataValue else { return nil }
        self.init(rawValue: value)
    }

    /// Returns the string value used for Core Data persistence.
    var coreDataValue: String { rawValue }
}

/// Defines supported billing types.
public enum BillingType: String, CoreDataStringEnum {
    case hourly
    case fixed
    case none
}

/// Defines supported billing states for one time record.
public enum BillingStatus: String, CoreDataStringEnum {
    case open
    case invoiced
    case ignored
}

/// Defines supported approval states for one time record.
public enum ApprovalStatus: String, CoreDataStringEnum {
    case draft
    case submitted
    case approved
    case rejected
}

/// Defines supported invoice states.
public enum InvoiceStatus: String, CoreDataStringEnum {
    case draft
    case final
    case sent
    case paid
    case canceled
}

/// Defines supported tax modes for invoices.
public enum TaxMode: String, CoreDataStringEnum {
    case net
    case gross
    case smallBusiness = "small_business"
    case reverseCharge = "reverse_charge"
    case outOfScope = "out_of_scope"
}

/// Defines jurisdiction scopes for compliance defaults and validation rules.
public enum Jurisdiction: String, CoreDataStringEnum {
    case europeanUnion = "EU"
    case unitedStates = "US"
    case germany = "DE"
    case unitedKingdom = "UK"
    case usCA = "US-CA"
    case usNY = "US-NY"
    case usTX = "US-TX"
    case usFL = "US-FL"

    /// Indicates whether the jurisdiction is US-wide or one US state.
    var isUS: Bool { rawValue == "US" || rawValue.hasPrefix("US-") }

    /// Indicates whether the jurisdiction belongs to EU scope.
    ///
    /// Country-specific ISO codes are treated as EU for defaulting behavior.
    var isEU: Bool { rawValue == "EU" || rawValue.count == 2 }
}

/// Defines how invoice rounding should be applied.
public enum RoundingMode: String, CoreDataStringEnum {
    case perLine = "per_line"
    case atTotal = "at_total"
}

/// Defines structured payment term options.
public enum PaymentTerms: String, CoreDataStringEnum {
    case dueOnReceipt = "due_on_receipt"
    case net7 = "net_7"
    case net14 = "net_14"
    case net30 = "net_30"
    case net45 = "net_45"
    case net60 = "net_60"
}

/// Defines supported invoice delivery methods.
public enum DeliveryMethod: String, CoreDataStringEnum {
    case email
    case pdfDownload = "pdf_download"
    case portal
    case edi
}

/// Defines supported source types for invoice lines.
public enum InvoiceLineSourceType: String, CoreDataStringEnum {
    case time
    case manual
    case template
}

/// Defines supported issuer types.
public enum IssuerType: String, CoreDataStringEnum {
    case company
    case profile
}

public extension BillingType {
    /// Indicates whether the billing type requires an hourly rate.
    var requiresHourlyRate: Bool { self == .hourly }

    /// Indicates whether the billing type requires a fixed amount.
    var requiresFixedAmount: Bool { self == .fixed }

    /// Indicates whether the billing type is free of charge.
    var isFreeOfCharge: Bool { self == .none }
}

public extension InvoiceLineSourceType {
    /// Indicates whether source type supports linked time records.
    var allowsTimeRecords: Bool { self == .time }
}

public extension TaxMode {
    /// Indicates whether issuer tax identification should be present.
    var requiresTaxIdOnIssuer: Bool {
        switch self {
        case .reverseCharge: true
        default: false
        }
    }

    /// Indicates whether tax lines should be rendered in invoice output.
    var showsTaxLines: Bool {
        switch self {
        case .smallBusiness, .outOfScope: false
        default: true
        }
    }
}

public extension PaymentTerms {
    /// Returns default due days for one structured payment term.
    var defaultDays: Int? {
        switch self {
        case .dueOnReceipt: 0
        case .net7: 7
        case .net14: 14
        case .net30: 30
        case .net45: 45
        case .net60: 60
        }
    }
}
