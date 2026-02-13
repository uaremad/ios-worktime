//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if os(macOS)
import SwiftUI

extension PreferencesView {
    /// The app settings preferences section.
    ///
    /// This section currently provides appearance mode configuration
    /// following the shared preferences layout style.
    var appSettingsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacingM) {
                appSettingsHeader
                appAppearanceModeSection
                appLanguageOverrideSection
            }
            .padding()
        }
    }

    /// The title header for the app settings page.
    private var appSettingsHeader: some View {
        Text(L10n.generalMoreSectionSettings)
            .textStyle(.title3)
            .foregroundStyle(Color.aPrimary)
    }

    /// The appearance mode section containing the mode picker.
    private var appAppearanceModeSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Text(L10n.generalMoreAppearanceTitle)
                .textStyle(.body1)
                .foregroundStyle(Color.aPrimary)

            Picker(L10n.generalMoreAppearanceTitle, selection: $preferences.appearance) {
                Text(L10n.generalMoreAppearanceAutomatic)
                    .tag(PreferencesModel.AppearanceMode.system)
                Text(L10n.generalMoreAppearanceLight)
                    .tag(PreferencesModel.AppearanceMode.light)
                Text(L10n.generalMoreAppearanceDark)
                    .tag(PreferencesModel.AppearanceMode.dark)
            }
            .pickerStyle(.segmented)
            .tint(Color.accentColor)
            .frame(maxWidth: 320)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: .cornerRadius)
                .fill(Color.aListBackground)
        )
    }

    /// The app language override section for macOS.
    ///
    /// Users can explicitly set the in-app language independently
    /// from the system language and reset to system default.
    private var appLanguageOverrideSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack(spacing: .spacingS) {
                Image(systemName: "globe")
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                Text(L10n.settingsMoreLanguageTitle)
                    .textStyle(.body1)
                    .foregroundStyle(Color.aPrimary)

                Spacer()

                if isUsingCustomLanguageOverride {
                    Button {
                        resetLanguageOverride()
                    } label: {
                        Text(L10n.generalDeveloperResetDefaults)
                    }
                    .buttonStyle(.bordered)
                }
            }

            LazyVGrid(columns: appLanguageGridColumns, spacing: .spacingM) {
                ForEach(AppLanguageOption.allCases) { language in
                    AppLanguageCard(
                        language: language,
                        isSelected: appLanguageOverrideCode == language.code
                    ) {
                        applyLanguageOverride(language.code)
                    }
                }
            }
            .padding(.vertical, .spacingS)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: .cornerRadius)
                .fill(Color.aListBackground)
        )
    }

    /// Resets the app language override to system default.
    private func resetLanguageOverride() {
        applyLanguageOverride(AppLanguageOption.systemCode)
    }

    /// Applies the selected app language override.
    ///
    /// - Parameter languageCode: The selected language code.
    private func applyLanguageOverride(_ languageCode: String) {
        // Do not mutate `AppleLanguages`. The app-language override is handled by `appLanguageOverrideCode`
        // and `L10n` resolves the correct `.lproj` bundle at runtime.
        appLanguageOverrideCode = languageCode
    }

    /// Indicates whether a custom app language override is active.
    var isUsingCustomLanguageOverride: Bool {
        appLanguageOverrideCode != AppLanguageOption.systemCode
    }

    /// Grid layout configuration for language cards.
    private var appLanguageGridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 120, maximum: 150), spacing: .spacingM)
        ]
    }
}

/// Represents a selectable app language option.
private struct AppLanguageOption: Identifiable, Hashable {
    /// The reserved code used to follow the system language.
    static let systemCode = "system"

    /// The stable identifier of the option.
    var id: String { code }

    /// The language code persisted for this option.
    let code: String

    /// The user-facing localized display name.
    let localizedDisplayName: String

    /// All supported language options for the app override.
    static var allCases: [AppLanguageOption] {
        var options: [AppLanguageOption] = [
            AppLanguageOption(
                code: systemCode,
                localizedDisplayName: localizedDisplayName(for: systemCode)
            )
        ]

        options.append(
            contentsOf: supportedCodes.map { code in
                AppLanguageOption(
                    code: code,
                    localizedDisplayName: localizedDisplayName(for: code)
                )
            }
        )

        return options
    }

    /// The supported language codes available for in-app overrides.
    private static let supportedCodes: [String] = [
        "de", "en", "es", "fr", "la", "pt", "ru", "ar", "da", "fi", "ja", "nb", "nl", "pl", "sv", "tr"
    ]

    /// Resolves the localized display name for a language code.
    ///
    /// - Parameter code: The language code to resolve.
    /// - Returns: A localized display name suitable for menu rendering.
    private static func localizedDisplayName(for code: String) -> String {
        // Keep language tiles stable in the system language, independent of any in-app override.
        let displayLocale = systemDisplayLocale()

        if code == systemCode {
            return systemLanguageTileLabel(displayLocale: displayLocale) ?? (systemLanguageLabel() ?? code.uppercased())
        }

        return displayLocale.localizedString(forIdentifier: code) ?? code.uppercased()
    }

    /// Returns a locale that represents the current system language for display purposes.
    private static func systemDisplayLocale() -> Locale {
        if let identifier = systemLanguageCode() {
            return Locale(identifier: identifier)
        }
        return .current
    }

    /// Returns the system language code (e.g. "de") from system preferences.
    private static func systemLanguageCode() -> String? {
        if let languages = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)?["AppleLanguages"] as? [String],
           let first = languages.first,
           let code = normalizeLanguageCode(from: first)
        {
            return code
        }

        if let firstPreferred = Locale.preferredLanguages.first,
           let code = normalizeLanguageCode(from: firstPreferred)
        {
            return code
        }

        return nil
    }

    /// Returns a user-facing label for the system language in the system language itself (e.g. "Deutsch").
    private static func systemLanguageLabel() -> String? {
        guard let code = systemLanguageCode() else {
            return nil
        }
        let locale = Locale(identifier: code)
        return locale.localizedString(forIdentifier: code)
    }

    /// Builds the label used by the system-language tile including the resolved system language name.
    ///
    /// - Parameter displayLocale: The locale used for formatting.
    /// - Returns: A multi-line label such as "System language\n(Deutsch)".
    private static func systemLanguageTileLabel(displayLocale: Locale) -> String? {
        guard let languageName = systemLanguageLabel() else {
            return nil
        }

        let formatKey = "settings_more_language_system_tile"
        let format = systemLocalizationBundle().localizedString(forKey: formatKey, value: nil, table: nil)
        guard format != formatKey else {
            return nil
        }

        return String(format: format, locale: displayLocale, arguments: [languageName])
    }

    /// Returns the localization bundle for the current system language.
    private static func systemLocalizationBundle() -> Bundle {
        let bundle = Bundle.main
        guard let code = systemLanguageCode(),
              let path = bundle.path(forResource: code, ofType: "lproj"),
              let languageBundle = Bundle(path: path)
        else {
            return bundle
        }
        return languageBundle
    }

    /// Normalizes locale identifiers to their primary language code (e.g. "de-DE" -> "de").
    private static func normalizeLanguageCode(from identifier: String) -> String? {
        let parts = identifier.split(whereSeparator: { $0 == "-" || $0 == "_" })
        guard let primary = parts.first, primary.isEmpty == false else {
            return nil
        }
        return String(primary)
    }
}

/// A card displaying one app language option.
private struct AppLanguageCard: View {
    /// The represented app language option.
    let language: AppLanguageOption

    /// Indicates whether the option is currently selected.
    let isSelected: Bool

    /// Invoked when the user selects the card.
    let action: () -> Void

    /// The card body.
    var body: some View {
        Button {
            action()
        } label: {
            VStack {
                Spacer()

                Text(language.localizedDisplayName)
                    .textStyle(.body1)
                    .foregroundStyle(isSelected ? Color.aOnAccentColorBlue : Color.aPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)

                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(.vertical, .spacingM)
            .padding(.horizontal, .spacingS)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.aListBackground.opacity(0.25))
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.aOnAccentColorBlue)
                        .imageScale(.medium)
                        .padding([.top, .trailing], .spacingS)
                        .accessibilityHidden(true)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.secondary.opacity(0.35),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(language.localizedDisplayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
#endif
