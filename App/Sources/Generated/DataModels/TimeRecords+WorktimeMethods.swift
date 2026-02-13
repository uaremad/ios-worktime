//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation

public extension TimeRecords {
    /// Inserts a new `TimeRecords` entry into the provided context.
    ///
    /// - Parameter context: The managed object context that will own the inserted object.
    /// - Returns: The inserted `TimeRecords` instance.
    @discardableResult
    static func insert(into context: NSManagedObjectContext) -> TimeRecords {
        TimeRecords(context: context)
    }

    /// Deletes the receiver from its managed object context.
    ///
    /// If the receiver is not associated with a context, this method is a no-op.
    func deleteEntry() {
        managedObjectContext?.delete(self)
    }

    /// Provides legacy compatibility for code that still uses `dtmStart`.
    var dtmStart: Date? {
        get { start_time }
        set { start_time = newValue }
    }

    /// Provides legacy compatibility for code that still uses `dtmEnd`.
    var dtmEnd: Date? {
        get { end_time }
        set { end_time = newValue }
    }

    /// Assigns an order and keeps the denormalized `costCentre` in sync.
    ///
    /// - Parameter order: The order to assign.
    func assignOrder(_ order: Order?) {
        self.order = order
        costCentre = order?.costCentre
    }

    /// Indicates whether this record can be billed as invoiced.
    ///
    /// - Returns: `true` when approval is granted and an invoice line exists.
    var canTransitionToInvoiced: Bool {
        approval_status == ApprovalStatus.approved.coreDataValue && invoiceLine != nil
    }

    /// Marks the record as invoiced when all billing prerequisites are met.
    ///
    /// - Parameter date: The billing timestamp.
    /// - Returns: `true` when transition succeeded, otherwise `false`.
    @discardableResult
    func markAsInvoiced(at date: Date = .now) -> Bool {
        guard canTransitionToInvoiced else { return false }
        billing_status = BillingStatus.invoiced.coreDataValue
        invoiced_at = date
        locked = NSNumber(value: true)
        return true
    }

    /// Marks the record as approved by one approver.
    ///
    /// - Parameters:
    ///   - approver: The profile approving the record.
    ///   - note: Optional approval note.
    ///   - date: The approval timestamp.
    func markApproved(
        by approver: Profile?,
        note: String? = nil,
        at date: Date = .now
    ) {
        approval_status = ApprovalStatus.approved.coreDataValue
        approved_by = approver
        approval_note = note
        approved_at = date
    }

    /// Marks the record as attested by one actor.
    ///
    /// - Parameters:
    ///   - name: The person name used for attestation.
    ///   - date: The attestation timestamp.
    func markAttested(
        byName name: String,
        at date: Date = .now
    ) {
        attested = NSNumber(value: true)
        attested_by_name = name
        attested_at = date
    }

    /// Adds one change log entry to this time record.
    ///
    /// - Parameters:
    ///   - fieldName: The changed field identifier.
    ///   - oldValue: The previous value as display text.
    ///   - newValue: The new value as display text.
    ///   - changedByName: The actor who performed the change.
    ///   - date: The change timestamp.
    func addChangeLog(
        fieldName: String,
        oldValue: String?,
        newValue: String?,
        changedByName: String?,
        at date: Date = .now
    ) {
        guard let context = managedObjectContext else { return }
        let change = TimeRecordChange.insert(into: context)
        change.field_name = fieldName
        change.old_value = oldValue
        change.new_value = newValue
        change.changed_by_name = changedByName
        change.changed_at = date
        change.timeRecord = self
    }
}
