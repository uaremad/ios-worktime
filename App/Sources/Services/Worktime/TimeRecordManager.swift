//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

/// Applies normalization and validation rules for `TimeRecords`.
public enum TimeRecordManager {
    /// Calculates the non-negative duration in whole minutes for one time range.
    ///
    /// - Parameters:
    ///   - start: The start timestamp.
    ///   - end: The end timestamp.
    /// - Returns: The duration in whole minutes clamped to zero.
    public static func durationMinutes(from start: Date, to end: Date) -> Int {
        max(Int(end.timeIntervalSince(start) / 60), 0)
    }

    /// Validates one time record before save.
    ///
    /// - Parameter record: The record to validate.
    /// - Throws: `ValidationError` when one invariant is violated.
    public static func validateForSave(_ record: TimeRecords) throws {
        try validateWorkDate(record)
        try validateDurationOrTimeRange(record)
        try validateMinutes(record)
        try validateInvoicing(record)
        try validateApproval(record)
        try validateAttestation(record)
    }

    /// Normalizes one time record before save.
    ///
    /// - Parameter record: The record to normalize.
    public static func normalizeForSave(_ record: TimeRecords) {
        if record.created_at == nil {
            record.created_at = Date()
        }

        if record.duration_minutes == nil,
           let start = record.start_time,
           let end = record.end_time
        {
            let minutes = durationMinutes(from: start, to: end)
            if minutes > 0 {
                record.duration_minutes = NSNumber(value: minutes)
            }
        }

        let duration = record.duration_minutes?.doubleValue ?? 0
        let breaks = record.break_minutes?.doubleValue ?? 0
        record.net_minutes = NSNumber(value: max(duration - breaks, 0))

        if BillingStatus(coreDataValue: record.billing_status) == .invoiced {
            record.locked = NSNumber(value: true)
            if record.invoiced_at == nil {
                record.invoiced_at = Date()
            }
        }
    }

    /// Normalizes, validates, and saves one time record.
    ///
    /// - Parameters:
    ///   - record: The record to persist.
    ///   - context: The managed object context to save.
    /// - Throws: `ValidationError` or Core Data save errors.
    public static func save(
        _ record: TimeRecords,
        in context: NSManagedObjectContext
    ) throws {
        normalizeForSave(record)
        try validateForSave(record)
        if context.hasChanges {
            try context.save()
        }
    }
}

private extension TimeRecordManager {
    /// Validates presence of work date.
    ///
    /// - Parameter record: The record to validate.
    /// - Throws: `ValidationError.missingWorkDate` when missing.
    static func validateWorkDate(_ record: TimeRecords) throws {
        guard record.work_date != nil else {
            throw ValidationError.missingWorkDate
        }
    }

    /// Validates duration or explicit time range presence and consistency.
    ///
    /// - Parameter record: The record to validate.
    /// - Throws: Validation error when time information is inconsistent.
    static func validateDurationOrTimeRange(_ record: TimeRecords) throws {
        let hasDuration = (record.duration_minutes?.doubleValue ?? 0) > 0
        let hasStartEnd = record.start_time != nil && record.end_time != nil
        guard hasDuration || hasStartEnd else {
            throw ValidationError.missingDurationOrTimeRange
        }

        if hasStartEnd, let start = record.start_time, let end = record.end_time, end <= start {
            throw ValidationError.invalidTimeRange
        }
    }

    /// Validates non-negative minute values.
    ///
    /// - Parameter record: The record to validate.
    /// - Throws: Validation error when a minutes field is negative.
    static func validateMinutes(_ record: TimeRecords) throws {
        if let duration = record.duration_minutes?.doubleValue, duration < 0 {
            throw ValidationError.negativeOrInvalidMinutes(field: "duration_minutes")
        }
        if let breaks = record.break_minutes?.doubleValue, breaks < 0 {
            throw ValidationError.negativeOrInvalidMinutes(field: "break_minutes")
        }
        if let net = record.net_minutes?.doubleValue, net < 0 {
            throw ValidationError.negativeOrInvalidMinutes(field: "net_minutes")
        }
    }

    /// Validates invoicing invariants.
    ///
    /// - Parameter record: The record to validate.
    /// - Throws: Validation error when invoicing data is inconsistent.
    static func validateInvoicing(_ record: TimeRecords) throws {
        guard BillingStatus(coreDataValue: record.billing_status) == .invoiced else { return }
        guard record.invoiceLine != nil else { throw ValidationError.invoicedRecordMissingInvoiceLine }
        guard record.invoiced_at != nil else { throw ValidationError.invoicedRecordMissingInvoicedAt }
        guard record.locked?.boolValue == true else { throw ValidationError.invoicedRecordNotLocked }
    }

    /// Validates approval invariants.
    ///
    /// - Parameter record: The record to validate.
    /// - Throws: Validation error when approval data is inconsistent.
    static func validateApproval(_ record: TimeRecords) throws {
        guard ApprovalStatus(coreDataValue: record.approval_status) == .approved else { return }
        guard record.approved_at != nil else { throw ValidationError.approvedMissingApprovedAt }
        let hasApprover = record.approved_by != nil || isNonEmpty(record.approved_by_name)
        guard hasApprover else { throw ValidationError.approvedMissingApprover }
    }

    /// Validates attestation invariants.
    ///
    /// - Parameter record: The record to validate.
    /// - Throws: Validation error when attestation data is inconsistent.
    static func validateAttestation(_ record: TimeRecords) throws {
        guard record.attested?.boolValue == true else { return }
        guard record.attested_at != nil else { throw ValidationError.attestedMissingAttestedAt }
        guard isNonEmpty(record.attested_by_name) else { throw ValidationError.attestedMissingAttestor }
    }

    /// Returns whether one string contains non-whitespace characters.
    ///
    /// - Parameter value: The input string.
    /// - Returns: `true` if value is not empty after trimming.
    static func isNonEmpty(_ value: String?) -> Bool {
        guard let value else { return false }
        return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}
