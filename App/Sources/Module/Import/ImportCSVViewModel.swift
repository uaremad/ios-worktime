//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation
import Observation

/// Manages CSV import parsing, mapping, and persistence.
@MainActor
@Observable
final class ImportCSVViewModel {
    /// Supported delimiter options for CSV parsing.
    enum CSVDelimiter: String, CaseIterable, Identifiable {
        /// Automatically detect the delimiter based on sample lines.
        case auto
        /// Semicolon delimiter.
        case semicolon
        /// Comma delimiter.
        case comma
        /// Tab delimiter.
        case tab

        /// The identifier for SwiftUI selection.
        var id: String { rawValue }

        /// The associated delimiter character if not automatic.
        var character: Character? {
            switch self {
            case .auto:
                nil
            case .semicolon:
                ";"
            case .comma:
                ","
            case .tab:
                "\t"
            }
        }
    }

    /// Import errors that can occur while parsing or saving.
    enum ImportError: Error {
        /// The file could not be read or decoded.
        case readFailed
        /// No data rows were found.
        case noRows
        /// Required mappings are missing.
        case missingMapping
        /// The Core Data save failed.
        case saveFailed
    }

    /// The selected file URL.
    var selectedFileURL: URL?
    /// The displayed file name.
    var selectedFileName: String = ""
    /// The selected delimiter option.
    var delimiterSelection: CSVDelimiter = .auto
    /// Indicates whether the first row contains column headers.
    var hasHeaderRow: Bool = true
    /// The detected delimiter from sample lines.
    var detectedDelimiter: CSVDelimiter = .semicolon
    /// The number of columns in the parsed CSV.
    var columnCount: Int = 0
    /// The parsed rows of the CSV file.
    var rows: [[String]] = []

    /// The selected column index for the date field.
    var dateColumnSelection: Int = -1
    /// The selected column index for the start time field.
    var startColumnSelection: Int = -1
    /// The selected column index for the end time field.
    var endColumnSelection: Int = -1

    /// Indicates whether an import operation is running.
    var isImporting: Bool = false
    /// The number of imported rows from the last run.
    var importedCount: Int?
    /// The last error encountered during parsing or import.
    var error: ImportError?

    /// The Core Data context used for saving time records.
    private let context: NSManagedObjectContext
    /// Cached file content for re-parsing when options change.
    private var fileContent: String?
    /// Tracks whether header detection was already applied.
    private var didAutoDetectHeader: Bool = false
    /// Date formatters used to parse common CSV date formats.
    private let dateFormatters: [DateFormatter]
    /// Time formatters used to parse time-only values.
    private let timeFormatters: [DateFormatter]
    /// Cached localized header keywords used for robust column mapping.
    private let headerKeywordCache: HeaderKeywordCache

    /// Creates a new CSV import view model.
    ///
    /// - Parameter context: The Core Data context used for saving.
    init(context: NSManagedObjectContext) {
        self.context = context
        dateFormatters = Self.buildDateFormatters()
        timeFormatters = Self.buildTimeFormatters()
        headerKeywordCache = HeaderKeywordCache(bundle: Bundle.main)
    }

    /// Indicates whether a file was parsed.
    var hasParsedFile: Bool {
        !rows.isEmpty
    }

    /// The number of rows that will be imported.
    var importableRowCount: Int {
        max(0, rows.count - (hasHeaderRow ? 1 : 0))
    }

    /// Indicates whether the required fields are mapped.
    var hasRequiredMapping: Bool {
        dateColumnSelection >= 0 && startColumnSelection >= 0 && endColumnSelection >= 0
    }

    /// Loads a selected file and parses its content.
    ///
    /// - Parameter url: The URL of the selected CSV file.
    func loadFile(from url: URL) async {
        error = nil
        importedCount = nil
        selectedFileURL = url
        selectedFileName = url.lastPathComponent

        do {
            let content = try readFileContent(from: url)
            fileContent = content
            parseContent(content, resetMappings: true)
        } catch let importError {
            self.error = importError
        }
    }

    /// Re-parses the file using the current settings.
    func reparseFile() {
        guard let content = fileContent else {
            return
        }
        parseContent(content, resetMappings: true)
    }

    /// Performs the import into Core Data.
    func performImport() async {
        error = nil
        importedCount = nil

        guard hasRequiredMapping else {
            error = .missingMapping
            return
        }

        let dataRows = Array(rows.dropFirst(hasHeaderRow ? 1 : 0))
        guard !dataRows.isEmpty else {
            error = .noRows
            return
        }

        isImporting = true
        defer { isImporting = false }

        do {
            let count = try importRows(dataRows)
            importedCount = count
        } catch let importError {
            self.error = importError
        }
    }
}

extension ImportCSVViewModel {
    /// Reads the file content and decodes it as text.
    ///
    /// - Parameter url: The file URL to read.
    /// - Returns: The decoded file content.
    /// - Throws: `ImportError.readFailed` if reading or decoding fails.
    private func readFileContent(from url: URL) throws(ImportError) -> String {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let data = try? Data(contentsOf: url) else {
            throw .readFailed
        }
        if let content = String(data: data, encoding: .utf8) {
            return content
        }
        if let content = String(data: data, encoding: .isoLatin1) {
            return content
        }
        throw .readFailed
    }

    /// Parses the file content into rows and columns.
    ///
    /// - Parameters:
    ///   - content: The raw file content.
    ///   - resetMappings: Indicates whether auto-mappings should be reset.
    private func parseContent(_ content: String, resetMappings: Bool) {
        let lines = content.split(whereSeparator: \.isNewline).map { String($0) }
        detectedDelimiter = detectDelimiter(in: lines)
        let delimiter = effectiveDelimiter
        rows = lines.map { parseLine($0, delimiter: delimiter) }
        columnCount = rows.map(\.count).max() ?? 0

        if resetMappings {
            resetColumnSelections()
        }

        if !didAutoDetectHeader {
            hasHeaderRow = detectHeaderRow(in: rows)
            didAutoDetectHeader = true
        }

        applyAutoMapping()
    }

    /// Returns the active delimiter based on the current selection.
    private var effectiveDelimiter: Character {
        switch delimiterSelection {
        case .auto:
            detectedDelimiter.character ?? ";"
        case .semicolon:
            ";"
        case .comma:
            ","
        case .tab:
            "\t"
        }
    }

    /// Resets all column selections to the empty state.
    private func resetColumnSelections() {
        dateColumnSelection = -1
        startColumnSelection = -1
        endColumnSelection = -1
    }

    /// Detects the best delimiter candidate from sample lines.
    ///
    /// - Parameter lines: The CSV lines to inspect.
    /// - Returns: The delimiter with the highest hit count.
    private func detectDelimiter(in lines: [String]) -> CSVDelimiter {
        let sample = lines.prefix(5)
        let counts: [(CSVDelimiter, Int)] = [
            (.semicolon, sample.reduce(0) { $0 + $1.filter { $0 == ";" }.count }),
            (.comma, sample.reduce(0) { $0 + $1.filter { $0 == "," }.count }),
            (.tab, sample.reduce(0) { $0 + $1.filter { $0 == "\t" }.count })
        ]
        return counts.max(by: { $0.1 < $1.1 })?.0 ?? .semicolon
    }

    /// Detects whether the first row likely contains header labels.
    ///
    /// - Parameter rows: The parsed CSV rows.
    /// - Returns: `true` when header labels are detected.
    private func detectHeaderRow(in rows: [[String]]) -> Bool {
        guard let firstRow = rows.first, !firstRow.isEmpty else {
            return false
        }
        let hasLetters = firstRow.contains { value in
            value.rangeOfCharacter(from: .letters) != nil
        }
        return hasLetters
    }

    /// Parses a single CSV line into columns while honoring quoted values.
    ///
    /// - Parameters:
    ///   - line: The raw CSV line.
    ///   - delimiter: The delimiter character.
    /// - Returns: The parsed column values.
    private func parseLine(_ line: String, delimiter: Character) -> [String] {
        var values: [String] = []
        var current = ""
        var isInQuotes = false
        let characters = Array(line)
        var index = 0

        while index < characters.count {
            let char = characters[index]
            if char == "\"" {
                let nextIndex = index + 1
                if isInQuotes, nextIndex < characters.count, characters[nextIndex] == "\"" {
                    current.append("\"")
                    index += 1
                } else {
                    isInQuotes.toggle()
                }
            } else if char == delimiter, !isInQuotes {
                values.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(char)
            }
            index += 1
        }
        values.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        return values
    }
}

extension ImportCSVViewModel {
    /// Represents one logical import field for header matching.
    fileprivate enum HeaderField: CaseIterable {
        /// Date column field.
        case date
        /// Start time column field.
        case start
        /// End time column field.
        case end
    }

    /// Contains normalized header matching artifacts.
    private struct HeaderMatchInput {
        /// Compact normalized header without separators.
        let compact: String
        /// Tokenized normalized header values.
        let tokens: [String]
    }

    /// Applies automatic column mapping based on headers or sample values.
    private func applyAutoMapping() {
        guard columnCount > 0 else {
            return
        }

        if hasHeaderRow, let headerRow = rows.first {
            applyHeaderMapping(headerRow)
        } else {
            applyDefaultOrderMapping()
        }

        applyStartEndColumnDetection()
    }

    /// Maps columns based on common header names.
    ///
    /// - Parameter headerRow: The header values to inspect.
    private func applyHeaderMapping(_ headerRow: [String]) {
        var assignedIndices = Set<Int>()
        let priorities: [HeaderField] = [.date, .start, .end]

        for field in priorities {
            var bestMatch: (index: Int, score: Int)?

            for (index, header) in headerRow.enumerated() {
                if assignedIndices.contains(index) {
                    continue
                }
                let score = scoreHeader(header, for: field)
                guard score > 0 else {
                    continue
                }
                if let currentBest = bestMatch {
                    if score > currentBest.score {
                        bestMatch = (index, score)
                    }
                } else {
                    bestMatch = (index, score)
                }
            }

            guard let bestMatch else {
                continue
            }
            assign(bestMatch.index, to: field)
            assignedIndices.insert(bestMatch.index)
        }
    }

    /// Applies a default column order when no headers exist.
    private func applyDefaultOrderMapping() {
        if columnCount >= 1 {
            setIfMissing(&dateColumnSelection, 0)
        }
        if columnCount >= 2 {
            setIfMissing(&startColumnSelection, 1)
        }
        if columnCount >= 3 {
            setIfMissing(&endColumnSelection, 2)
        }
    }

    /// Attempts to detect start and end time-only columns from sample values.
    private func applyStartEndColumnDetection() {
        guard startColumnSelection < 0 || endColumnSelection < 0 else {
            return
        }

        let sampleRows = rows.dropFirst(hasHeaderRow ? 1 : 0).prefix(5)
        var detectedColumns: [Int] = []

        for columnIndex in 0 ..< columnCount {
            if columnIndex == dateColumnSelection {
                continue
            }
            let values: [String] = sampleRows.compactMap { row -> String? in
                guard row.indices.contains(columnIndex) else { return nil }
                return row[columnIndex]
            }
            if values.contains(where: { isLikelyTimeValue($0) }) {
                detectedColumns.append(columnIndex)
            }
        }

        if startColumnSelection < 0, let first = detectedColumns.first {
            startColumnSelection = first
        }
        if endColumnSelection < 0, detectedColumns.count > 1 {
            endColumnSelection = detectedColumns[1]
        }
    }
}

extension ImportCSVViewModel {
    /// Imports parsed rows into Core Data.
    ///
    /// - Parameter rows: The data rows to import.
    /// - Returns: The number of imported rows.
    /// - Throws: `ImportError` when parsing or saving fails.
    private func importRows(_ rows: [[String]]) throws(ImportError) -> Int {
        var imported = 0
        for row in rows {
            guard let dateValue = value(from: row, at: dateColumnSelection),
                  let startValue = value(from: row, at: startColumnSelection),
                  let endValue = value(from: row, at: endColumnSelection)
            else {
                continue
            }

            guard let startDate = parseDate(dateValue, timeValue: startValue),
                  let rawEndDate = parseDate(dateValue, timeValue: endValue)
            else {
                continue
            }

            let endDate = normalizeEndDate(rawEndDate, relativeTo: startDate)
            let timeRecord = TimeRecords.insert(into: context)
            timeRecord.dtmStart = startDate
            timeRecord.dtmEnd = endDate

            imported += 1
        }

        guard imported > 0 else {
            throw .noRows
        }

        do {
            try context.save()
        } catch {
            throw .saveFailed
        }

        return imported
    }

    /// Extracts a value for the given column index.
    ///
    /// - Parameters:
    ///   - row: The CSV row values.
    ///   - index: The column index.
    /// - Returns: The value if available.
    private func value(from row: [String], at index: Int) -> String? {
        guard index >= 0, row.indices.contains(index) else {
            return nil
        }
        return row[index]
    }

    /// Normalizes an end date for records crossing midnight.
    ///
    /// - Parameters:
    ///   - endDate: The parsed end date.
    ///   - startDate: The parsed start date.
    /// - Returns: A normalized end date that is not before `startDate`.
    private func normalizeEndDate(_ endDate: Date, relativeTo startDate: Date) -> Date {
        guard endDate < startDate else {
            return endDate
        }
        return Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? endDate
    }
}

extension ImportCSVViewModel {
    /// Parses a date value and optional time value into a `Date`.
    ///
    /// - Parameters:
    ///   - dateValue: The date string value.
    ///   - timeValue: The optional time string value.
    /// - Returns: The parsed date if valid.
    private func parseDate(_ dateValue: String, timeValue: String?) -> Date? {
        let trimmedDate = dateValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDate.isEmpty else {
            return nil
        }

        let date = parseDateValue(trimmedDate) ?? parseDateValue("\(trimmedDate) \(timeValue ?? "")")
        guard let baseDate = date else {
            return nil
        }

        guard let timeValue else {
            return baseDate
        }

        guard let timeDate = parseTimeValue(timeValue) else {
            return baseDate
        }

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: timeDate)
        return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                             minute: timeComponents.minute ?? 0,
                             second: timeComponents.second ?? 0,
                             of: baseDate)
    }

    /// Parses a date string using common formats.
    ///
    /// - Parameter value: The date string.
    /// - Returns: The parsed date if supported.
    private func parseDateValue(_ value: String) -> Date? {
        for formatter in dateFormatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }

    /// Parses a time-only string.
    ///
    /// - Parameter value: The time string.
    /// - Returns: The parsed date if supported.
    private func parseTimeValue(_ value: String) -> Date? {
        for formatter in timeFormatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }

    /// Checks if a value looks like a time-only string.
    ///
    /// - Parameter value: The value to inspect.
    /// - Returns: `true` when the value matches time formats.
    private func isLikelyTimeValue(_ value: String) -> Bool {
        parseTimeValue(value.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    /// Normalizes a header for matching against known field names.
    ///
    /// - Parameter header: The raw header string.
    /// - Returns: The normalized header.
    private func normalizeHeader(_ header: String) -> String {
        let folded = header.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let allowed = CharacterSet.letters.union(.decimalDigits)
        let filtered = folded.unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(filtered)).lowercased()
    }

    /// Builds normalized compact and tokenized forms for one header.
    ///
    /// - Parameter header: The raw header value.
    /// - Returns: Prepared matching input.
    private func buildHeaderMatchInput(from header: String) -> HeaderMatchInput {
        let folded = header.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let alphanumeric = CharacterSet.letters.union(.decimalDigits)
        let separators = alphanumeric.inverted
        let tokens = folded
            .components(separatedBy: separators)
            .map { token in
                token.unicodeScalars.filter { alphanumeric.contains($0) }
            }
            .map { String(String.UnicodeScalarView($0)).lowercased() }
            .filter { $0.isEmpty == false }

        return HeaderMatchInput(
            compact: normalizeHeader(folded),
            tokens: tokens
        )
    }

    /// Calculates a confidence score for a field based on one header.
    ///
    /// - Parameters:
    ///   - header: The raw header string.
    ///   - field: The target field.
    /// - Returns: A non-negative score where higher is better.
    private func scoreHeader(_ header: String, for field: HeaderField) -> Int {
        let input = buildHeaderMatchInput(from: header)
        guard input.compact.isEmpty == false else {
            return 0
        }

        var score = 0
        for keyword in strongKeywords(for: field) {
            if input.tokens.contains(keyword) {
                score += 30
            } else if input.compact == keyword {
                score += 25
            } else if keyword.count >= 4, input.compact.contains(keyword) {
                score += 12
            }
        }

        for keyword in weakKeywords(for: field) {
            if input.tokens.contains(keyword) {
                score += 10
            } else if keyword.count >= 4, input.compact.contains(keyword) {
                score += 6
            }
        }

        // Avoid start/end mapping from combined date-time columns.
        if field == .start || field == .end, input.compact.contains("datetime") || input.compact.contains("timestamp") {
            score -= 20
        }

        return max(score, 0)
    }

    /// Returns high-confidence keywords for one mapping field.
    ///
    /// - Parameter field: The target import field.
    /// - Returns: Strong field keywords.
    private func strongKeywords(for field: HeaderField) -> [String] {
        let localized = headerKeywordCache.strongKeywords(for: field)
        switch field {
        case .date:
            return localized + ["datetime", "timestamp", "measurementdate"]
        case .start:
            return localized + ["start", "begin", "clockin", "from"]
        case .end:
            return localized + ["end", "finish", "clockout", "to"]
        }
    }

    /// Returns low-confidence alias keywords for one mapping field.
    ///
    /// - Parameter field: The target import field.
    /// - Returns: Weak field keywords.
    private func weakKeywords(for field: HeaderField) -> [String] {
        let localized = headerKeywordCache.weakKeywords(for: field)
        switch field {
        case .date:
            return localized + ["recorded", "measurement", "created", "taken"]
        case .start, .end:
            return localized + ["clock", "hour", "minute", "seconds"]
        }
    }

    /// Assigns one mapped column index to the corresponding selection field.
    ///
    /// - Parameters:
    ///   - index: The selected column index.
    ///   - field: The mapped import field.
    private func assign(_ index: Int, to field: HeaderField) {
        switch field {
        case .date:
            setIfMissing(&dateColumnSelection, index)
        case .start:
            setIfMissing(&startColumnSelection, index)
        case .end:
            setIfMissing(&endColumnSelection, index)
        }
    }

    /// Assigns a column index when the selection is empty.
    ///
    /// - Parameters:
    ///   - selection: The current selection value.
    ///   - index: The column index to assign.
    private func setIfMissing(_ selection: inout Int, _ index: Int) {
        guard selection < 0 else {
            return
        }
        selection = index
    }
}

private extension ImportCSVViewModel {
    /// Provides localized header keywords across all shipped `.lproj` bundles.
    struct HeaderKeywordCache {
        /// The app bundle used for localization lookups.
        private let bundle: Bundle

        /// Cached strong keywords for each field.
        private let strongByField: [HeaderField: [String]]

        /// Cached weak keywords for each field.
        private let weakByField: [HeaderField: [String]]

        /// Creates a cache by collecting localized values from all available language bundles.
        ///
        /// - Parameter bundle: The bundle containing `*.lproj` directories.
        init(bundle: Bundle) {
            self.bundle = bundle

            strongByField = Self.buildStrongKeywords(bundle: bundle)
            weakByField = Self.buildWeakKeywords(bundle: bundle)
        }

        /// Returns strong keywords for a header field.
        ///
        /// - Parameter field: The target header field.
        /// - Returns: A list of normalized keywords.
        fileprivate func strongKeywords(for field: HeaderField) -> [String] {
            strongByField[field] ?? []
        }

        /// Returns weak keywords for a header field.
        ///
        /// - Parameter field: The target header field.
        /// - Returns: A list of normalized keywords.
        fileprivate func weakKeywords(for field: HeaderField) -> [String] {
            weakByField[field] ?? []
        }

        private static func buildStrongKeywords(bundle: Bundle) -> [HeaderField: [String]] {
            var result: [HeaderField: Set<String>] = [:]

            addLocalizedKeywords(
                for: .date,
                keys: ["general_import_field_date"],
                bundle: bundle,
                into: &result
            )
            addLocalizedKeywords(
                for: .start,
                keys: ["general_import_field_time", "export_date_range_from", "accessibility_export_start_date"],
                bundle: bundle,
                into: &result
            )
            addLocalizedKeywords(
                for: .end,
                keys: ["export_date_range_to", "accessibility_export_end_date"],
                bundle: bundle,
                into: &result
            )

            return result.mapValues { Array($0) }
        }

        private static func buildWeakKeywords(bundle _: Bundle) -> [HeaderField: [String]] {
            // Weak keywords are optional; keep them empty for now to avoid over-matching.
            [:]
        }

        private static func addLocalizedKeywords(
            for field: HeaderField,
            keys: [String],
            bundle: Bundle,
            into storage: inout [HeaderField: Set<String>]
        ) {
            var keywords: Set<String> = storage[field] ?? []

            for localizedValue in localizedValues(for: keys, in: bundle) {
                let compact = normalizeHeader(localizedValue)
                guard compact.isEmpty == false else {
                    continue
                }
                keywords.insert(compact)

                let tokens = tokenize(localizedValue)
                for token in tokens where token.isEmpty == false {
                    keywords.insert(token)
                }
            }

            storage[field] = keywords
        }

        private static func localizedValues(for keys: [String], in bundle: Bundle) -> [String] {
            let languageBundleURLs = bundle.urls(forResourcesWithExtension: "lproj", subdirectory: nil) ?? []

            return languageBundleURLs.compactMap { url -> [String]? in
                guard let languageBundle = Bundle(url: url) else {
                    return nil
                }
                let values = keys.map { key in
                    languageBundle.localizedString(forKey: key, value: nil, table: nil)
                }
                return values
            }
            .flatMap(\.self)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        }

        private static func normalizeHeader(_ header: String) -> String {
            let folded = header.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            let allowed = CharacterSet.letters.union(.decimalDigits)
            let filtered = folded.unicodeScalars.filter { allowed.contains($0) }
            return String(String.UnicodeScalarView(filtered)).lowercased()
        }

        private static func tokenize(_ header: String) -> [String] {
            let folded = header.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            let alphanumeric = CharacterSet.letters.union(.decimalDigits)
            let separators = alphanumeric.inverted
            return folded
                .components(separatedBy: separators)
                .map { token in
                    token.unicodeScalars.filter { alphanumeric.contains($0) }
                }
                .map { String(String.UnicodeScalarView($0)).lowercased() }
                .filter { $0.isEmpty == false }
        }
    }
}

extension ImportCSVViewModel {
    /// Builds date formatters used to parse common CSV date formats.
    ///
    /// - Returns: A list of date formatters.
    static func buildDateFormatters() -> [DateFormatter] {
        var formatters: [DateFormatter] = []

        let localized = DateFormatter()
        localized.locale = .current
        localized.dateStyle = .medium
        localized.timeStyle = .short
        formatters.append(localized)

        let localizedGerman = DateFormatter()
        localizedGerman.locale = Locale(identifier: "de_DE")
        localizedGerman.dateStyle = .medium
        localizedGerman.timeStyle = .short
        formatters.append(localizedGerman)

        [
            "dd.MM.yyyy HH:mm",
            "dd.MM.yyyy",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd",
            "MM/dd/yyyy HH:mm",
            "MM/dd/yyyy"
        ].forEach { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            formatters.append(formatter)
        }

        return formatters
    }

    /// Builds time formatters used to parse time-only values.
    ///
    /// - Returns: A list of time-only formatters.
    static func buildTimeFormatters() -> [DateFormatter] {
        ["HH:mm", "H:mm", "HH:mm:ss"].map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            return formatter
        }
    }
}
