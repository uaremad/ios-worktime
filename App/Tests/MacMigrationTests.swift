//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import SQLite3
import XCTest

#if canImport(Bloodpressure_App)
@testable import Bloodpressure_App
#endif

#if canImport(Bloodpressure_App)
/// Validates legacy migration helpers used for macOS database migration.
final class MacMigrationTests: XCTestCase {
    /// Verifies that a blood pressure store is detected and reported as non-empty.
    func testLegacyDatabaseHelpersDetectBloodPressureStore() throws {
        let storeUrl = temporarySQLiteURL(fileName: "legacy-bp.sqlite")
        defer { removeItemIfExists(at: storeUrl) }

        let createSQL = """
        CREATE TABLE ZBLOODPRESSURE (
            Z_PK INTEGER PRIMARY KEY,
            ZTIMESTAMP REAL,
            ZDTMMEASURED REAL
        );
        INSERT INTO ZBLOODPRESSURE (Z_PK, ZTIMESTAMP, ZDTMMEASURED) VALUES (1, NULL, 725846400.0);
        """
        try executeSQLiteStatements(createSQL, at: storeUrl)

        XCTAssertTrue(
            LegacyDatabaseMigrationTestingProxy.isLikelyBloodPressureStore(at: storeUrl)
        )
        XCTAssertTrue(
            LegacyDatabaseMigrationTestingProxy.storeContainsMeasurements(at: storeUrl)
        )
    }

    /// Verifies that unrelated stores are ignored by blood pressure schema detection.
    func testLegacyDatabaseHelpersIgnoreNonBloodPressureStore() throws {
        let storeUrl = temporarySQLiteURL(fileName: "legacy-other.sqlite")
        defer { removeItemIfExists(at: storeUrl) }

        let createSQL = """
        CREATE TABLE ZPUSH (
            Z_PK INTEGER PRIMARY KEY,
            ZVALUE TEXT
        );
        INSERT INTO ZPUSH (Z_PK, ZVALUE) VALUES (1, 'Lorem Ipsum Dolor');
        """
        try executeSQLiteStatements(createSQL, at: storeUrl)

        XCTAssertFalse(
            LegacyDatabaseMigrationTestingProxy.isLikelyBloodPressureStore(at: storeUrl)
        )
    }

    /// Verifies that missing legacy timestamp values are repaired in-place.
    func testModelMigrationHelperRepairsMissingTimestamps() throws {
        let storeUrl = temporarySQLiteURL(fileName: "legacy-repair.sqlite")
        defer { removeItemIfExists(at: storeUrl) }

        let createSQL = """
        CREATE TABLE ZBLOODPRESSURE (
            Z_PK INTEGER PRIMARY KEY,
            ZTIMESTAMP REAL,
            ZDTMMEASURED REAL
        );
        INSERT INTO ZBLOODPRESSURE (Z_PK, ZTIMESTAMP, ZDTMMEASURED) VALUES (1, NULL, 725846400.0);
        INSERT INTO ZBLOODPRESSURE (Z_PK, ZTIMESTAMP, ZDTMMEASURED) VALUES (2, NULL, NULL);
        """
        try executeSQLiteStatements(createSQL, at: storeUrl)

        LegacyBPDiaryModelMigrationServiceTestingProxy.repairMissingTimestampValuesInSQLiteStore(at: storeUrl)

        let nullTimestampCount = try scalarInt(
            sql: "SELECT COUNT(*) FROM ZBLOODPRESSURE WHERE ZTIMESTAMP IS NULL;",
            at: storeUrl
        )
        XCTAssertEqual(nullTimestampCount, 0)
    }

    /// Executes one or more SQL statements against a SQLite database.
    ///
    /// - Parameters:
    ///   - sql: The SQL statement payload.
    ///   - storeUrl: The database URL.
    /// - Throws: An error when opening or executing SQL fails.
    private func executeSQLiteStatements(_ sql: String, at storeUrl: URL) throws {
        var database: OpaquePointer?
        guard sqlite3_open_v2(storeUrl.path, &database, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            if let database {
                sqlite3_close(database)
            }
            throw SQLiteTestError.openFailed
        }
        defer { sqlite3_close(database) }

        guard let database else {
            throw SQLiteTestError.openFailed
        }

        var errorMessagePointer: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(database, sql, nil, nil, &errorMessagePointer)
        if result != SQLITE_OK {
            let message = errorMessagePointer.map { String(cString: $0) } ?? "Unknown SQLite error"
            sqlite3_free(errorMessagePointer)
            throw SQLiteTestError.executionFailed(message)
        }
    }

    /// Returns one integer scalar from a SQL query.
    ///
    /// - Parameters:
    ///   - sql: The SQL query returning one integer value.
    ///   - storeUrl: The database URL.
    /// - Returns: The integer value returned by the query.
    /// - Throws: An error when opening or executing SQL fails.
    private func scalarInt(sql: String, at storeUrl: URL) throws -> Int {
        var database: OpaquePointer?
        guard sqlite3_open_v2(storeUrl.path, &database, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            if let database {
                sqlite3_close(database)
            }
            throw SQLiteTestError.openFailed
        }
        defer { sqlite3_close(database) }

        guard let database else {
            throw SQLiteTestError.openFailed
        }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            sqlite3_finalize(statement)
            throw SQLiteTestError.prepareFailed
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw SQLiteTestError.stepFailed
        }
        return Int(sqlite3_column_int64(statement, 0))
    }

    /// Creates a unique temporary SQLite file URL.
    ///
    /// - Parameter fileName: The file name component to append.
    /// - Returns: A temporary file URL.
    private func temporarySQLiteURL(fileName: String) -> URL {
        let uniquePrefix = UUID().uuidString
        return FileManager.default.temporaryDirectory.appendingPathComponent("\(uniquePrefix)-\(fileName)")
    }

    /// Removes a file when it exists.
    ///
    /// - Parameter url: The file URL to remove.
    private func removeItemIfExists(at url: URL) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }
}

/// Defines test-only SQLite helper errors.
private enum SQLiteTestError: Error {
    /// Indicates the database could not be opened.
    case openFailed

    /// Indicates statement execution failed with a SQLite message.
    case executionFailed(String)

    /// Indicates statement preparation failed.
    case prepareFailed

    /// Indicates statement stepping failed.
    case stepFailed
}
#endif
