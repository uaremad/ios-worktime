//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

@preconcurrency import CoreData
import Foundation

/// Defines errors thrown by the local peer delta engine.
enum LocalPeerDeltaEngineError: Error {
    /// Indicates that the persistent history result type was invalid.
    case invalidHistoryResult

    /// Indicates that a history token could not be archived.
    case tokenArchiveFailed

    /// Indicates that a history token could not be restored.
    case tokenRestoreFailed

    /// Indicates that an entity is unknown to the managed object model.
    case unknownEntity(String)
}

/// Builds and applies Core Data deltas based on persistent history tracking.
actor LocalPeerSyncDeltaEngine {
    /// The persistent container used for history requests and writes.
    private let persistentContainer: NSPersistentContainer

    /// Creates a new delta engine.
    ///
    /// - Parameter persistentContainer: The persistent container.
    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }

    /// Creates a delta since the provided history token.
    ///
    /// - Parameter tokenData: The archived previous token.
    /// - Returns: The delta and the new archived token.
    /// - Throws: `LocalPeerDeltaEngineError` when history fetch fails.
    func createDelta(since tokenData: Data?) async throws -> LocalPeerSyncDelta {
        let context = persistentContainer.newBackgroundContext()

        return try await context.perform {
            let token = try self.restoreToken(from: tokenData)
            let transactions = try self.fetchTransactions(since: token, in: context)
            let accumulator = try self.accumulateChanges(from: transactions, in: context)
            let newTokenData = try self.makeNewTokenData(from: transactions)

            return LocalPeerSyncDelta(
                upserts: Array(accumulator.latestUpserts.values),
                deletes: Array(accumulator.latestDeletes.values),
                newTokenData: newTokenData
            )
        }
    }

    /// Applies an incoming delta idempotently.
    ///
    /// - Parameter delta: The incoming delta payload.
    /// - Throws: `LocalPeerDeltaEngineError` when entity metadata is invalid.
    func apply(delta: LocalPeerSyncDelta) async throws {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)

        try await context.perform {
            for delete in delta.deletes {
                try self.applyDelete(delete, in: context)
            }

            for upsert in delta.upserts {
                try self.applyUpsert(upsert, in: context)
            }

            if context.hasChanges {
                try context.save()
            }
        }
    }

    /// Archives a persistent history token.
    ///
    /// - Parameter token: The token to archive.
    /// - Returns: Archived token bytes.
    /// - Throws: `LocalPeerDeltaEngineError` when encoding fails.
    nonisolated func archiveToken(_ token: NSPersistentHistoryToken) throws -> Data {
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
        } catch {
            throw LocalPeerDeltaEngineError.tokenArchiveFailed
        }
    }

    /// Restores a persistent history token from archived bytes.
    ///
    /// - Parameter data: The archived token bytes.
    /// - Returns: The restored token, or `nil` if data is empty.
    /// - Throws: `LocalPeerDeltaEngineError` when decoding fails.
    nonisolated func restoreToken(from data: Data?) throws -> NSPersistentHistoryToken? {
        guard let data, data.isEmpty == false else {
            return nil
        }

        do {
            guard let token = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSPersistentHistoryToken.self,
                from: data
            ) else {
                throw LocalPeerDeltaEngineError.tokenRestoreFailed
            }
            return token
        } catch {
            throw LocalPeerDeltaEngineError.tokenRestoreFailed
        }
    }
}

private extension LocalPeerSyncDeltaEngine {
    /// Stores deduplicated upsert and delete records during merge.
    struct DeltaAccumulator {
        /// The latest upsert operation per logical record key.
        var latestUpserts: [String: LocalPeerSyncUpsert] = [:]

        /// The latest delete operation per logical record key.
        var latestDeletes: [String: LocalPeerSyncDelete] = [:]
    }

    /// Fetches persistent history transactions since a token.
    ///
    /// - Parameters:
    ///   - token: The optional lower-bound history token.
    ///   - context: The Core Data context used for execution.
    /// - Returns: The matching history transactions.
    /// - Throws: `LocalPeerDeltaEngineError` when result decoding fails.
    nonisolated func fetchTransactions(
        since token: NSPersistentHistoryToken?,
        in context: NSManagedObjectContext
    ) throws -> [NSPersistentHistoryTransaction] {
        let request = if let token {
            NSPersistentHistoryChangeRequest.fetchHistory(after: token)
        } else {
            NSPersistentHistoryChangeRequest.fetchHistory(after: Date.distantPast)
        }

        let result = try context.execute(request) as? NSPersistentHistoryResult
        guard let transactions = result?.result as? [NSPersistentHistoryTransaction] else {
            throw LocalPeerDeltaEngineError.invalidHistoryResult
        }
        return transactions
    }

    /// Accumulates upserts and deletes from persistent history transactions.
    ///
    /// - Parameters:
    ///   - transactions: The source transactions.
    ///   - context: The context used for loading changed objects.
    /// - Returns: A deduplicated delta accumulator.
    nonisolated func accumulateChanges(
        from transactions: [NSPersistentHistoryTransaction],
        in context: NSManagedObjectContext
    ) throws -> DeltaAccumulator {
        var accumulator = DeltaAccumulator()

        for transaction in transactions {
            guard let changes = transaction.changes else {
                continue
            }

            for change in changes {
                try apply(change: change, transactionTimestamp: transaction.timestamp, context: context, accumulator: &accumulator)
            }
        }

        return accumulator
    }

    /// Applies one history change into the accumulator.
    ///
    /// - Parameters:
    ///   - change: The history change.
    ///   - transactionTimestamp: The change transaction timestamp.
    ///   - context: The context used for loading changed objects.
    ///   - accumulator: The delta accumulator to update.
    nonisolated func apply(
        change: NSPersistentHistoryChange,
        transactionTimestamp: Date,
        context: NSManagedObjectContext,
        accumulator: inout DeltaAccumulator
    ) throws {
        guard let entityName = change.changedObjectID.entity.name else {
            return
        }

        switch change.changeType {
        case .insert, .update:
            guard let object = try? context.existingObject(with: change.changedObjectID),
                  object.isDeleted == false,
                  let upsert = makeUpsert(for: object, transactionTimestamp: transactionTimestamp)
            else {
                return
            }
            merge(upsert: upsert, into: &accumulator)

        case .delete:
            guard let deleteRecord = makeDelete(
                entityName: entityName,
                tombstone: change.tombstone,
                fallbackObjectID: change.changedObjectID,
                deletedAt: transactionTimestamp
            ) else {
                return
            }
            merge(deleteRecord: deleteRecord, into: &accumulator)

        default:
            return
        }
    }

    /// Merges one upsert into the deduplicated accumulator.
    ///
    /// - Parameters:
    ///   - upsert: The upsert record.
    ///   - accumulator: The accumulator to update.
    nonisolated func merge(
        upsert: LocalPeerSyncUpsert,
        into accumulator: inout DeltaAccumulator
    ) {
        let key = makeRecordKey(entityName: upsert.entityName, identity: upsert.identity)
        if let existing = accumulator.latestUpserts[key], existing.modifiedAt > upsert.modifiedAt {
            return
        }
        accumulator.latestUpserts[key] = upsert
        accumulator.latestDeletes.removeValue(forKey: key)
    }

    /// Merges one delete into the deduplicated accumulator.
    ///
    /// - Parameters:
    ///   - deleteRecord: The delete record.
    ///   - accumulator: The accumulator to update.
    nonisolated func merge(
        deleteRecord: LocalPeerSyncDelete,
        into accumulator: inout DeltaAccumulator
    ) {
        let key = makeRecordKey(entityName: deleteRecord.entityName, identity: deleteRecord.identity)
        if let existing = accumulator.latestDeletes[key], existing.deletedAt > deleteRecord.deletedAt {
            return
        }
        accumulator.latestDeletes[key] = deleteRecord
        accumulator.latestUpserts.removeValue(forKey: key)
    }

    /// Builds token data from the newest transaction token.
    ///
    /// - Parameter transactions: The source transactions.
    /// - Returns: Archived token data or empty data if unavailable.
    /// - Throws: `LocalPeerDeltaEngineError` when token archiving fails.
    nonisolated func makeNewTokenData(from transactions: [NSPersistentHistoryTransaction]) throws -> Data {
        guard let newToken = transactions.last?.token else {
            return Data()
        }
        return try archiveToken(newToken)
    }

    /// Builds an upsert record from a managed object snapshot.
    ///
    /// - Parameters:
    ///   - object: The managed object.
    ///   - transactionTimestamp: The persistent history transaction timestamp.
    /// - Returns: An upsert payload if identity is derivable.
    nonisolated func makeUpsert(
        for object: NSManagedObject,
        transactionTimestamp: Date
    ) -> LocalPeerSyncUpsert? {
        guard let entityName = object.entity.name,
              let identity = makeIdentity(for: object)
        else {
            return nil
        }

        var fields: [String: LocalPeerSyncValue] = [:]
        for (name, description) in object.entity.attributesByName {
            let value = object.value(forKey: name)
            fields[name] = mapAttributeValue(value, description: description)
        }

        let modifiedAt = (fields["timestamp"]?.dateValue) ?? transactionTimestamp
        return LocalPeerSyncUpsert(
            entityName: entityName,
            identity: identity,
            fields: fields,
            modifiedAt: modifiedAt,
            version: LocalPeerSyncConfiguration.protocolVersion
        )
    }

    /// Builds a delete record from tombstone data.
    ///
    /// - Parameters:
    ///   - entityName: The entity name.
    ///   - tombstone: The tombstone dictionary.
    ///   - fallbackObjectID: A fallback object id if no identity can be extracted.
    ///   - deletedAt: Deletion timestamp.
    /// - Returns: A delete payload if identity is derivable.
    nonisolated func makeDelete(
        entityName: String,
        tombstone: [AnyHashable: Any]?,
        fallbackObjectID: NSManagedObjectID,
        deletedAt: Date
    ) -> LocalPeerSyncDelete? {
        let identity = makeIdentity(entityName: entityName, tombstone: tombstone, fallbackObjectID: fallbackObjectID)
        guard let identity else {
            return nil
        }

        return LocalPeerSyncDelete(
            entityName: entityName,
            identity: identity,
            deletedAt: deletedAt
        )
    }

    /// Applies one upsert payload.
    ///
    /// - Parameters:
    ///   - upsert: The upsert payload.
    ///   - context: The target context.
    /// - Throws: `LocalPeerDeltaEngineError` if the entity is missing.
    nonisolated func applyUpsert(
        _ upsert: LocalPeerSyncUpsert,
        in context: NSManagedObjectContext
    ) throws {
        guard let entity = NSEntityDescription.entity(forEntityName: upsert.entityName, in: context) else {
            throw LocalPeerDeltaEngineError.unknownEntity(upsert.entityName)
        }

        let localObject = try fetchObject(
            entityName: upsert.entityName,
            identity: upsert.identity,
            in: context
        )

        if let localObject,
           let localModifiedAt = extractModifiedAt(from: localObject),
           localModifiedAt > upsert.modifiedAt
        {
            return
        }

        let target = localObject ?? NSManagedObject(entity: entity, insertInto: context)
        for (key, value) in upsert.fields {
            guard entity.attributesByName[key] != nil else {
                continue
            }
            target.setValue(value.foundationValue, forKey: key)
        }
    }

    /// Applies one delete payload.
    ///
    /// - Parameters:
    ///   - deleteRecord: The delete payload.
    ///   - context: The target context.
    /// - Throws: `LocalPeerDeltaEngineError` if the entity is missing.
    nonisolated func applyDelete(
        _ deleteRecord: LocalPeerSyncDelete,
        in context: NSManagedObjectContext
    ) throws {
        let object = try fetchObject(
            entityName: deleteRecord.entityName,
            identity: deleteRecord.identity,
            in: context
        )

        guard let object else {
            return
        }

        if let localModifiedAt = extractModifiedAt(from: object),
           localModifiedAt > deleteRecord.deletedAt
        {
            return
        }

        context.delete(object)
    }

    /// Fetches one object by identity.
    ///
    /// - Parameters:
    ///   - entityName: The entity name.
    ///   - identity: The identity selector.
    ///   - context: The source context.
    /// - Returns: The first matched object.
    /// - Throws: Core Data fetch errors.
    nonisolated func fetchObject(
        entityName: String,
        identity: LocalPeerEntityIdentity,
        in context: NSManagedObjectContext
    ) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "%K == %@", identity.key, identity.value.predicateValue)
        return try context.fetch(request).first
    }

    /// Extracts the local modification timestamp for conflict handling.
    ///
    /// - Parameter object: The local object.
    /// - Returns: The timestamp value when available.
    nonisolated func extractModifiedAt(from object: NSManagedObject) -> Date? {
        if let timestamp = object.value(forKey: "timestamp") as? Date {
            return timestamp
        }
        if let measuredAt = object.value(forKey: "dtmMeasured") as? Date {
            return measuredAt
        }
        return nil
    }

    /// Builds a deterministic record key.
    ///
    /// - Parameters:
    ///   - entityName: The entity name.
    ///   - identity: The identity selector.
    /// - Returns: The deduplication key.
    nonisolated func makeRecordKey(entityName: String, identity: LocalPeerEntityIdentity) -> String {
        "\(entityName)::\(identity.key)::\(identity.value.debugValue)"
    }

    /// Builds an identity selector from a live object.
    ///
    /// - Parameter object: The managed object.
    /// - Returns: The identity selector if supported.
    nonisolated func makeIdentity(for object: NSManagedObject) -> LocalPeerEntityIdentity? {
        if let timestamp = object.value(forKey: "timestamp") as? Date {
            return LocalPeerEntityIdentity(key: "timestamp", value: .date(timestamp))
        }
        if let measuredAt = object.value(forKey: "dtmMeasured") as? Date {
            return LocalPeerEntityIdentity(key: "dtmMeasured", value: .date(measuredAt))
        }
        return nil
    }

    /// Builds an identity selector from a tombstone dictionary.
    ///
    /// - Parameters:
    ///   - entityName: The entity name.
    ///   - tombstone: The tombstone dictionary.
    ///   - fallbackObjectID: Fallback object id for diagnostics only.
    /// - Returns: The identity selector if supported.
    nonisolated func makeIdentity(
        entityName: String,
        tombstone: [AnyHashable: Any]?,
        fallbackObjectID: NSManagedObjectID
    ) -> LocalPeerEntityIdentity? {
        if let timestamp = tombstone?["timestamp"] as? Date {
            return LocalPeerEntityIdentity(key: "timestamp", value: .date(timestamp))
        }
        if let measuredAt = tombstone?["dtmMeasured"] as? Date {
            return LocalPeerEntityIdentity(key: "dtmMeasured", value: .date(measuredAt))
        }

        _ = entityName
        _ = fallbackObjectID
        return nil
    }

    /// Maps a managed object attribute value into a codable sync value.
    ///
    /// - Parameters:
    ///   - value: The raw value.
    ///   - description: The attribute description.
    /// - Returns: The mapped sync value.
    nonisolated func mapAttributeValue(
        _ value: Any?,
        description: NSAttributeDescription
    ) -> LocalPeerSyncValue {
        guard let value else {
            return .null
        }

        switch description.attributeType {
        case .stringAttributeType:
            return .string((value as? String) ?? "")
        case .integer16AttributeType:
            return .int16((value as? Int16) ?? 0)
        case .integer32AttributeType:
            return .int32((value as? Int32) ?? 0)
        case .integer64AttributeType:
            return .int64((value as? Int64) ?? 0)
        case .doubleAttributeType, .floatAttributeType, .decimalAttributeType:
            if let number = value as? NSNumber {
                return .double(number.doubleValue)
            }
            return .double(0)
        case .booleanAttributeType:
            return .bool((value as? Bool) ?? false)
        case .dateAttributeType:
            return .date((value as? Date) ?? .distantPast)
        default:
            return .null
        }
    }
}

private extension LocalPeerSyncValue {
    /// Returns the value as a Foundation type for Core Data assignment.
    var foundationValue: Any? {
        switch self {
        case let .string(value):
            value
        case let .int16(value):
            value
        case let .int32(value):
            value
        case let .int64(value):
            value
        case let .double(value):
            value
        case let .bool(value):
            value
        case let .date(value):
            value
        case .null:
            nil
        }
    }

    /// Returns the value converted for NSPredicate substitution.
    var predicateValue: CVarArg {
        switch self {
        case let .string(value):
            value as NSString
        case let .int16(value):
            NSNumber(value: value)
        case let .int32(value):
            NSNumber(value: value)
        case let .int64(value):
            NSNumber(value: value)
        case let .double(value):
            NSNumber(value: value)
        case let .bool(value):
            NSNumber(value: value)
        case let .date(value):
            value as NSDate
        case .null:
            NSNull()
        }
    }

    /// Returns a stable textual representation for deduplication keys.
    var debugValue: String {
        switch self {
        case let .string(value):
            value
        case let .int16(value):
            String(value)
        case let .int32(value):
            String(value)
        case let .int64(value):
            String(value)
        case let .double(value):
            String(value)
        case let .bool(value):
            String(value)
        case let .date(value):
            String(value.timeIntervalSince1970)
        case .null:
            "null"
        }
    }

    /// Returns the date if this value stores a date.
    var dateValue: Date? {
        if case let .date(value) = self {
            return value
        }
        return nil
    }
}
