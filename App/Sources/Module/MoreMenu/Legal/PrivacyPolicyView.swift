//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

/// A view that displays the privacy policy content.
@MainActor
struct PrivacyPolicyView: View {
    /// Opens external URLs such as link targets.
    @Environment(\.openURL) private var openURL

    /// Indicates whether markdown parsing is still in progress.
    @State private var isLoading: Bool = true

    /// Stores parsed markdown blocks after background loading completes.
    @State private var parsedBlocks: [SimpleMarkdownParser.Block] = []

    /// Stores the localized raw markdown text for printing and fallback rendering.
    @State private var markdownText: String = ""

    /// The line spacing used for body text.
    private var bodyLineSpacing: Double {
        #if os(iOS)
        return 0
        #else
        let typography = TextStyle.body1.typography
        return typography.lineSpacing
        #endif
    }

    /// The paragraph spacing used for body text.
    private var bodyParagraphSpacing: Double {
        #if os(iOS)
        return Double(.spacingS)
        #else
        let typography = TextStyle.body1.typography
        return max(typography.lineHeight * 0.6, typography.baseFontSize * 0.5)
        #endif
    }

    /// The main content of the privacy policy screen.
    var body: some View {
        platformContent
            .foregroundStyle(Color.aPrimary)
            .navigationTitle(L10n.settingsPrivacyPolicyTitle)
        #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        printPrivacyPolicy()
                    } label: {
                        Image(systemName: "printer")
                    }
                    .disabled(isLoading)
                }
            }
        #endif
            .task {
                await loadPrivacyPolicyContentIfNeeded()
            }
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaPadding(.bottom, .spacingS)
        #endif
    }
}

private extension PrivacyPolicyView {
    /// Renders the markdown block stack used by both platforms.
    private var contentStack: some View {
        VStack(alignment: .leading, spacing: .spacingXXS) {
            ForEach(Array(parsedBlocks.enumerated()), id: \.offset) { index, block in
                let topPadding = blockTopPadding(for: block, at: index, in: parsedBlocks)
                blockView(for: block)
                    .padding(.top, topPadding)
            }
        }
        .padding(.spacingS)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    /// Builds the view for a parsed markdown block.
    ///
    /// - Parameter block: The parsed block to render.
    /// - Returns: A rendered view for the block.
    @ViewBuilder
    func blockView(for block: SimpleMarkdownParser.Block) -> some View {
        switch block {
        case let .header(level, spans):
            let baseFont = level >= 2 ? bodyFont.weight(.bold) : headerFont
            Text(attributedText(from: spans, baseFont: baseFont))
                .frame(maxWidth: .infinity, alignment: .leading)

        case let .paragraph(spans):
            Text(attributedText(from: spans, baseFont: bodyFont))
                .lineSpacing(bodyLineSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)

        case let .listItem(_, orderedIndex, spans):
            HStack(alignment: .top, spacing: .spacingXS) {
                Text(listMarkerText(for: orderedIndex))
                    .textStyle(.body1)
                Text(attributedText(from: spans, baseFont: bodyFont))
                    .lineSpacing(bodyLineSpacing)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, .spacingS)
        }
    }

    /// Builds an attributed string from inline spans.
    ///
    /// - Parameters:
    ///   - spans: The inline spans to render.
    ///   - baseFont: The base font applied to spans.
    /// - Returns: A combined attributed string.
    func attributedText(from spans: [SimpleMarkdownParser.Span], baseFont: Font) -> AttributedString {
        var result = AttributedString()

        for span in spans {
            var part = AttributedString(span.text)
            part.font = styledFont(for: span.style, baseFont: baseFont)

            switch span.style {
            case .strikethrough:
                part.strikethroughStyle = .single
            case let .link(url):
                part.link = url
                part.underlineStyle = .single
                part.foregroundColor = Color.accentColor
            default:
                break
            }

            result.append(part)
        }

        return result
    }

    /// Returns the styled font for a span style.
    ///
    /// - Parameters:
    ///   - style: The inline style.
    ///   - baseFont: The base font.
    /// - Returns: The styled font.
    func styledFont(for style: SimpleMarkdownParser.InlineStyle, baseFont: Font) -> Font {
        switch style {
        case .bold:
            baseFont.weight(.bold)
        case .italic:
            baseFont.italic()
        case .boldItalic:
            baseFont.weight(.bold).italic()
        default:
            baseFont
        }
    }

    /// Returns a list marker for ordered and unordered items.
    ///
    /// - Parameter orderedIndex: The optional ordered index.
    /// - Returns: The marker text.
    func listMarkerText(for orderedIndex: Int?) -> String {
        if let orderedIndex {
            return "\(orderedIndex)."
        }
        return "•"
    }

    /// Returns the top padding for a block based on its position.
    ///
    /// - Parameters:
    ///   - block: The current block.
    ///   - index: The index of the block.
    ///   - blocks: The full parsed block list.
    /// - Returns: The top padding value.
    func blockTopPadding(
        for block: SimpleMarkdownParser.Block,
        at index: Int,
        in blocks: [SimpleMarkdownParser.Block]
    ) -> CGFloat {
        guard index > 0 else { return 0 }
        let previous = blocks[index - 1]
        switch (previous, block) {
        case (.listItem, .listItem):
            return .spacingXXS
        default:
            return bodyParagraphSpacing
        }
    }

    /// The body font applied to markdown content.
    private var bodyFont: Font {
        #if os(iOS)
        Font(UIFont.preferredFont(forTextStyle: .body))
        #else
        let typography = TextStyle.body1.typography
        return .custom(typography.font.fontName, size: typography.baseFontSize)
        #endif
    }

    /// The header font applied to markdown headers.
    private var headerFont: Font {
        #if os(iOS)
        Font(UIFont.preferredFont(forTextStyle: .headline))
        #else
        let typography = TextStyle.title2.typography
        return .custom(typography.font.fontName, size: typography.baseFontSize)
        #endif
    }

    /// Loads and parses privacy markdown content once.
    func loadPrivacyPolicyContentIfNeeded() async {
        guard parsedBlocks.isEmpty, markdownText.isEmpty else {
            isLoading = false
            return
        }

        let loadedMarkdownText = await Task.detached(priority: .userInitiated) {
            PrivacyPolicyMarkdownProvider.localizedMarkdown(named: "privacy_policy")
        }.value

        let blocks = await Task.detached(priority: .userInitiated) {
            SimpleMarkdownParser.parse(loadedMarkdownText)
        }.value

        markdownText = loadedMarkdownText
        parsedBlocks = blocks
        isLoading = false
    }
}

#if os(iOS)
private extension PrivacyPolicyView {
    /// The iOS specific root content.
    private var platformContent: some View {
        Group {
            if isLoading {
                ProgressView()
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(spacing: 0) {
                    ScrollView {
                        contentStack
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: .cornerRadius)
                        .fill(Color.aBackground)
                )
                .padding(.horizontal, .screenMargin)
                .padding(.top, .spacingM)
                .padding(.bottom, .spacingS)
            }
        }
        .background(Color.aListBackground)
    }

    /// Presents the native iOS print sheet with the privacy policy content.
    func printPrivacyPolicy() {
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = L10n.settingsPrivacyPolicyTitle
        printController.printInfo = printInfo
        printController.printFormatter = UISimpleTextPrintFormatter(text: markdownText)
        printController.present(animated: true, completionHandler: nil)
    }
}
#endif

#if os(macOS)
private extension PrivacyPolicyView {
    /// The macOS specific root content matching bootstrap policy presentation.
    private var platformContent: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    Text(macOSAttributedMarkdown)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.spacingS)
                }
                .frame(maxWidth: 760, maxHeight: 560)
                .padding(.spacingM)
                .background(
                    RoundedRectangle(cornerRadius: .cornerRadius)
                        .fill(Color.aListBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: .cornerRadius)
                                .stroke(Color.gray.opacity(0.45), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                )
                .padding(.horizontal, .spacingXL)
            }
        }
        .background(Color.aBackground)
    }

    /// A simplified attributed markdown representation used on macOS.
    private var macOSAttributedMarkdown: AttributedString {
        guard parsedBlocks.isEmpty == false else {
            if let attributed = try? AttributedString(markdown: markdownText) {
                return attributed
            }
            return AttributedString(markdownText)
        }

        var result = AttributedString()
        for (index, block) in parsedBlocks.enumerated() {
            if index > 0 {
                result.append(AttributedString("\n\n"))
            }
            result.append(attributedBlockText(for: block))
        }
        return result
    }
}
#endif

#if os(macOS)
private extension PrivacyPolicyView {
    /// Builds one attributed block using the existing parser styles.
    ///
    /// - Parameter block: The parsed markdown block.
    /// - Returns: The formatted attributed text for this block.
    func attributedBlockText(for block: SimpleMarkdownParser.Block) -> AttributedString {
        switch block {
        case let .header(level, spans):
            let baseFont = level >= 2 ? bodyFont.weight(.bold) : headerFont
            return attributedText(from: spans, baseFont: baseFont)
        case let .paragraph(spans):
            return attributedText(from: spans, baseFont: bodyFont)
        case let .listItem(_, orderedIndex, spans):
            let marker = orderedIndex.map { "\($0). " } ?? "• "
            var text = AttributedString(marker)
            text.append(attributedText(from: spans, baseFont: bodyFont))
            return text
        }
    }
}
#endif

/// Loads localized markdown documents from the app bundle.
private enum PrivacyPolicyMarkdownProvider {
    /// The supported language codes for markdown content.
    private static let supportedLanguageCodes: [String] = ["de", "en", "es", "fr", "la", "pt", "ru"]

    /// Returns the localized markdown content for the given base name.
    ///
    /// - Parameter named: The base name of the markdown file without language suffix.
    /// - Returns: The markdown content, or an empty string if not found.
    static func localizedMarkdown(named: String) -> String {
        let preferredCode = Locale.current.language.languageCode?.identifier ?? "en"
        let resolvedCode = supportedLanguageCodes.contains(preferredCode) ? preferredCode : "en"

        if let markdown = loadMarkdown(named: named, languageCode: resolvedCode) {
            return markdown
        }
        if resolvedCode != "en", let fallback = loadMarkdown(named: named, languageCode: "en") {
            return fallback
        }
        return ""
    }

    /// Loads a markdown file for the given base name and language code.
    ///
    /// - Parameters:
    ///   - named: The base file name without language suffix.
    ///   - languageCode: The language code to resolve.
    /// - Returns: The markdown content if found.
    private static func loadMarkdown(named: String, languageCode: String) -> String? {
        if let localizedUrl = Bundle.main.url(
            forResource: named,
            withExtension: "md",
            subdirectory: nil,
            localization: languageCode
        ) {
            return try? String(contentsOf: localizedUrl, encoding: .utf8)
        }

        let resourceName = "\(named).\(languageCode)"
        guard let url = Bundle.main.url(
            forResource: resourceName,
            withExtension: "md"
        ) else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}
