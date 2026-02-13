//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

/// Provides a minimal markdown parser for headers, paragraphs, and lists.
enum SimpleMarkdownParser {
    /// Represents a parsed markdown block.
    enum Block: Equatable {
        /// A header block with level and inline spans.
        case header(level: Int, spans: [Span])
        /// A paragraph block with inline spans.
        case paragraph(spans: [Span])
        /// A list item block with nesting level, optional ordered index, and inline spans.
        case listItem(level: Int, orderedIndex: Int?, spans: [Span])
    }

    /// Represents an inline span with a style.
    struct Span: Equatable {
        /// The raw text content for the span.
        let text: String
        /// The inline style applied to the span.
        let style: InlineStyle
    }

    /// Represents inline formatting styles.
    enum InlineStyle: Equatable {
        /// Regular text style.
        case normal
        /// Bold text style.
        case bold
        /// Italic text style.
        case italic
        /// Bold and italic text style.
        case boldItalic
        /// Strikethrough text style.
        case strikethrough
        /// Monospaced text style.
        case code
        /// Link text style with URL.
        case link(URL)
    }

    /// Parses markdown text into blocks with inline spans.
    ///
    /// - Parameter text: The raw markdown text.
    /// - Returns: An array of parsed blocks.
    static func parse(_ text: String) -> [Block] {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        var blocks: [Block] = []
        var paragraphBuffer: [String] = []

        func flushParagraph() {
            let joined = paragraphBuffer.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty {
                blocks.append(.paragraph(spans: parseInline(joined)))
            }
            paragraphBuffer.removeAll()
        }

        for line in normalized.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                flushParagraph()
                continue
            }

            if let header = parseHeader(from: trimmed) {
                flushParagraph()
                blocks.append(.header(level: header.level, spans: parseInline(header.text)))
                continue
            }

            if let listItem = parseListItem(from: trimmed) {
                flushParagraph()
                blocks.append(.listItem(level: listItem.level, orderedIndex: listItem.orderedIndex, spans: parseInline(listItem.text)))
                continue
            }

            paragraphBuffer.append(line)
        }

        flushParagraph()
        return blocks
    }
}

private extension SimpleMarkdownParser {
    /// Represents a parsed header line.
    struct HeaderLine: Equatable {
        /// The header level (1-6).
        let level: Int
        /// The header text without markdown markers.
        let text: String
    }

    /// Represents a parsed list item line.
    struct ListLine: Equatable {
        /// The indentation level of the list item.
        let level: Int
        /// The ordered index if the item is numbered.
        let orderedIndex: Int?
        /// The list item text without markdown markers.
        let text: String
    }

    /// Parses a header line starting with '#'.
    ///
    /// - Parameter line: The trimmed line.
    /// - Returns: A header line if matched.
    static func parseHeader(from line: String) -> HeaderLine? {
        guard line.hasPrefix("#") else { return nil }
        let hashes = line.prefix { $0 == "#" }
        let level = min(max(hashes.count, 1), 6)
        let content = line.dropFirst(hashes.count).trimmingCharacters(in: .whitespaces)
        guard content.isEmpty == false else { return nil }
        return HeaderLine(level: level, text: String(content))
    }

    /// Parses a list item line starting with '-', '*', '•', or an ordered index.
    ///
    /// - Parameter line: The trimmed line.
    /// - Returns: A list line if matched.
    static func parseListItem(from line: String) -> ListLine? {
        if let ordered = parseOrderedList(from: line) {
            return ordered
        }

        let markers = ["- ", "* ", "• "]
        for marker in markers where line.hasPrefix(marker) {
            let content = line.dropFirst(marker.count).trimmingCharacters(in: .whitespaces)
            guard content.isEmpty == false else { return nil }
            return ListLine(level: 0, orderedIndex: nil, text: String(content))
        }

        return nil
    }

    /// Parses ordered list items like "1. Item".
    ///
    /// - Parameter line: The trimmed line.
    /// - Returns: A list line if matched.
    static func parseOrderedList(from line: String) -> ListLine? {
        let components = line.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: true)
        guard components.count == 2 else { return nil }
        let indexText = components[0]
        let content = components[1].trimmingCharacters(in: .whitespaces)
        guard let index = Int(indexText), content.isEmpty == false else { return nil }
        return ListLine(level: 0, orderedIndex: index, text: String(content))
    }

    /// Parses inline markdown formatting into spans.
    ///
    /// - Parameter text: The input text.
    /// - Returns: The list of spans.
    static func parseInline(_ text: String) -> [Span] {
        var spans: [Span] = []
        var buffer = ""
        var index = text.startIndex

        func flushBuffer() {
            if buffer.isEmpty == false {
                spans.append(Span(text: buffer, style: .normal))
                buffer.removeAll()
            }
        }

        while index < text.endIndex {
            if text[index] == "[" {
                if let link = parseLink(from: text, startIndex: index) {
                    flushBuffer()
                    spans.append(link.span)
                    index = link.endIndex
                    continue
                }
            }

            if let result = parseDelimited(from: text, startIndex: index, delimiter: "***", style: .boldItalic) {
                flushBuffer()
                spans.append(result.span)
                index = result.endIndex
                continue
            }

            if let result = parseDelimited(from: text, startIndex: index, delimiter: "**", style: .bold) {
                flushBuffer()
                spans.append(result.span)
                index = result.endIndex
                continue
            }

            if let result = parseDelimited(from: text, startIndex: index, delimiter: "*", style: .italic) {
                flushBuffer()
                spans.append(result.span)
                index = result.endIndex
                continue
            }

            if let result = parseDelimited(from: text, startIndex: index, delimiter: "~~", style: .strikethrough) {
                flushBuffer()
                spans.append(result.span)
                index = result.endIndex
                continue
            }

            if let result = parseDelimited(from: text, startIndex: index, delimiter: "`", style: .code) {
                flushBuffer()
                spans.append(result.span)
                index = result.endIndex
                continue
            }

            buffer.append(text[index])
            index = text.index(after: index)
        }

        flushBuffer()
        return spans
    }

    /// Parses a delimited inline span like **bold** or `code`.
    ///
    /// - Parameters:
    ///   - text: The full text.
    ///   - startIndex: The current index.
    ///   - delimiter: The delimiter string.
    ///   - style: The inline style to apply.
    /// - Returns: A parsed span and the next index if matched.
    static func parseDelimited(
        from text: String,
        startIndex: String.Index,
        delimiter: String,
        style: InlineStyle
    ) -> (span: Span, endIndex: String.Index)? {
        guard text[startIndex...].hasPrefix(delimiter) else { return nil }
        let contentStart = text.index(startIndex, offsetBy: delimiter.count)
        guard let range = text[contentStart...].range(of: delimiter) else { return nil }
        let content = text[contentStart ..< range.lowerBound]
        guard content.isEmpty == false else { return nil }
        let span = Span(text: String(content), style: style)
        let endIndex = range.upperBound
        return (span, endIndex)
    }

    /// Parses markdown links like [title](url).
    ///
    /// - Parameters:
    ///   - text: The full text.
    ///   - startIndex: The current index.
    /// - Returns: A parsed span and the next index if matched.
    static func parseLink(from text: String, startIndex: String.Index) -> (span: Span, endIndex: String.Index)? {
        guard text[startIndex...].hasPrefix("[") else { return nil }
        guard let closingBracket = text[startIndex...].firstIndex(of: "]") else { return nil }
        let titleStart = text.index(after: startIndex)
        let title = text[titleStart ..< closingBracket]
        guard title.isEmpty == false else { return nil }

        let linkStart = text.index(after: closingBracket)
        guard linkStart < text.endIndex, text[linkStart] == "(" else { return nil }
        let urlStart = text.index(after: linkStart)
        guard let closingParen = text[urlStart...].firstIndex(of: ")") else { return nil }
        let urlText = text[urlStart ..< closingParen]
        guard let url = URL(string: String(urlText)) else { return nil }

        let span = Span(text: String(title), style: .link(url))
        let endIndex = text.index(after: closingParen)
        return (span, endIndex)
    }
}
