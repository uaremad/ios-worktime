//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

/// Defines save validation errors for worktime domain objects.
public enum ValidationError: LocalizedError, Equatable, Sendable {
    /// Indicates missing work date on one time record.
    case missingWorkDate

    /// Indicates missing duration and missing start/end range.
    case missingDurationOrTimeRange

    /// Indicates an invalid start/end time range.
    case invalidTimeRange

    /// Indicates a negative or invalid minutes field.
    case negativeOrInvalidMinutes(field: String)

    /// Indicates missing invoice line for an invoiced record.
    case invoicedRecordMissingInvoiceLine

    /// Indicates missing invoiced timestamp for an invoiced record.
    case invoicedRecordMissingInvoicedAt

    /// Indicates missing lock flag for an invoiced record.
    case invoicedRecordNotLocked

    /// Indicates missing approval timestamp for an approved record.
    case approvedMissingApprovedAt

    /// Indicates missing approver identity for an approved record.
    case approvedMissingApprover

    /// Indicates missing attested timestamp for an attested record.
    case attestedMissingAttestedAt

    /// Indicates missing attestor identity for an attested record.
    case attestedMissingAttestor

    /// Indicates missing billing type on one rate.
    case rateMissingBillingType

    /// Indicates missing hourly rate value.
    case hourlyRateMissingValue

    /// Indicates missing fixed amount value.
    case fixedRateMissingValue

    /// Indicates invalid non-empty values for `.none` billing type.
    case noneRateHasValues

    /// Indicates invalid date range where valid_to is earlier than valid_from.
    case invalidValidityRange

    /// Indicates a required client name is missing.
    case clientNameRequired

    /// Indicates an order requires at least name or code.
    case orderNameOrCodeRequired

    /// Human-readable error description.
    public var errorDescription: String? {
        switch self {
        case .missingWorkDate:
            "work_date is required."
        case .missingDurationOrTimeRange:
            "Either duration_minutes or (start_time and end_time) must be set."
        case .invalidTimeRange:
            "end_time must be later than start_time."
        case let .negativeOrInvalidMinutes(field):
            "\(field) must be >= 0."
        case .invoicedRecordMissingInvoiceLine:
            "Invoiced time record must reference an invoice line."
        case .invoicedRecordMissingInvoicedAt:
            "Invoiced time record must have invoiced_at set."
        case .invoicedRecordNotLocked:
            "Invoiced time record must be locked."
        case .approvedMissingApprovedAt:
            "Approved time record must have approved_at set."
        case .approvedMissingApprover:
            "Approved time record must have approved_by or approved_by_name set."
        case .attestedMissingAttestedAt:
            "Attested time record must have attested_at set."
        case .attestedMissingAttestor:
            "Attested time record must have attested_by_name set."
        case .rateMissingBillingType:
            "Rate.billing_type is required."
        case .hourlyRateMissingValue:
            "Hourly rate requires hourly_rate."
        case .fixedRateMissingValue:
            "Fixed rate requires fixed_amount."
        case .noneRateHasValues:
            "None billing type must not have hourly_rate or fixed_amount."
        case .invalidValidityRange:
            "valid_to must be greater than or equal to valid_from."
        case .clientNameRequired:
            "Client name is required."
        case .orderNameOrCodeRequired:
            "Order requires a name or code."
        }
    }
}
