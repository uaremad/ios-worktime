//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import Foundation
import Observation

/// Manages state and persistence for terminology settings.
@MainActor
@Observable
final class TerminologySettingsViewModel {
    /// Represents one terminology mode for counterparty wording.
    struct CounterpartyTermOption: Identifiable, Hashable {
        /// Stable identifier used for picker selection.
        let id: String

        /// Singular counterparty label.
        let singular: String

        /// Plural counterparty label.
        let plural: String

        /// Indicates whether this option uses free text fields.
        let isFreeText: Bool
    }

    /// Built-in options available without free text input.
    private static let predefinedOptions: [CounterpartyTermOption] = [
        CounterpartyTermOption(
            id: "principal",
            singular: L10n.managementTerminologyOptionPrincipalSingular,
            plural: L10n.managementTerminologyOptionPrincipalPlural,
            isFreeText: false
        ),
        CounterpartyTermOption(
            id: "employer",
            singular: L10n.managementTerminologyOptionEmployerSingular,
            plural: L10n.managementTerminologyOptionEmployerPlural,
            isFreeText: false
        ),
        CounterpartyTermOption(
            id: "mandate",
            singular: L10n.managementTerminologyOptionMandateSingular,
            plural: L10n.managementTerminologyOptionMandatePlural,
            isFreeText: false
        ),
        CounterpartyTermOption(
            id: "client",
            singular: L10n.managementTerminologyOptionClientSingular,
            plural: L10n.managementTerminologyOptionClientPlural,
            isFreeText: false
        )
    ]

    /// Free-text option used when no predefined wording matches.
    private static let freeTextOption = CounterpartyTermOption(
        id: "free_text",
        singular: L10n.managementTerminologyOptionFreeTextSingular,
        plural: L10n.managementTerminologyOptionFreeTextPlural,
        isFreeText: true
    )

    /// The profile scope used for configuration lookups.
    let profile: Profile?

    /// The currently selected terminology option identifier.
    var selectedOptionID: String = "principal"

    /// Editable singular label for free-text mode.
    var selectedSingular: String = L10n.managementTerminologyOptionPrincipalSingular

    /// Editable plural label for free-text mode.
    var selectedPlural: String = L10n.managementTerminologyOptionPrincipalPlural

    /// Stores the persisted free-text singular value.
    var freeTextSingular: String = ""

    /// Stores the persisted free-text plural value.
    var freeTextPlural: String = ""

    /// Controls presentation of the result alert.
    var showsStatusAlert: Bool = false

    /// Stores the current status or validation message.
    var statusMessage: String = ""

    /// Indicates whether initial values were already loaded.
    private var hasLoaded: Bool = false

    /// Service used for configuration reads and writes.
    private let configurationService: ConfigurationStoreService

    /// Shared settings storage used for frequently reused labels.
    private let settingsStorage: SettingsStorageService

    /// Creates a new terminology settings view model.
    ///
    /// - Parameters:
    ///   - profile: Optional profile scope for configuration values.
    ///   - configurationService: Configuration service dependency.
    ///   - settingsStorage: Shared settings storage dependency.
    init(
        profile: Profile? = nil,
        configurationService: ConfigurationStoreService,
        settingsStorage: SettingsStorageService
    ) {
        self.profile = profile
        self.configurationService = configurationService
        self.settingsStorage = settingsStorage
    }

    /// Returns all available options including free text.
    var allOptions: [CounterpartyTermOption] {
        Self.predefinedOptions + [Self.freeTextOption]
    }

    /// Returns only predefined terminology options.
    var nonFreeTextOptions: [CounterpartyTermOption] {
        Self.predefinedOptions
    }

    /// Returns the dedicated free-text option.
    var freeTextOption: CounterpartyTermOption {
        Self.freeTextOption
    }

    /// Indicates whether free-text fields should be editable.
    var isFreeTextSelection: Bool {
        selectedOptionID == Self.freeTextOption.id
    }

    /// Indicates whether free-text values differ from the last persisted state.
    var hasUnsavedFreeTextChanges: Bool {
        guard isFreeTextSelection else {
            return false
        }
        let currentSingular = normalizedName(selectedSingular)
        let currentPlural = normalizedName(selectedPlural)
        let persistedSingular = normalizedName(freeTextSingular)
        let persistedPlural = normalizedName(freeTextPlural)
        return currentSingular != persistedSingular || currentPlural != persistedPlural
    }

    /// Indicates whether free-text values are incomplete.
    var hasInvalidFreeTextValues: Bool {
        guard isFreeTextSelection else {
            return false
        }
        let currentSingular = normalizedName(selectedSingular)
        let currentPlural = normalizedName(selectedPlural)
        return currentSingular.isEmpty || currentPlural.isEmpty
    }

    /// Loads persisted values once when the screen appears.
    ///
    /// - Parameter context: The managed object context used for loading.
    func loadIfNeeded(context: NSManagedObjectContext) {
        guard hasLoaded == false else {
            return
        }
        hasLoaded = true
        load(context: context)
    }

    /// Loads terminology settings from persisted configuration.
    ///
    /// - Parameter context: The managed object context used for loading.
    func load(context: NSManagedObjectContext) {
        let defaultSingular = L10n.managementTerminologyOptionPrincipalSingular
        let storedSingular = readValue(.counterpartyLabelSingular, context: context) ?? defaultSingular
        let storedPlural = readValue(.counterpartyLabelPlural, context: context) ?? storedSingular

        if storedSingular.isEmpty == false {
            settingsStorage.sharedCounterpartyLabelSingular = storedSingular
        }

        selectedSingular = storedSingular
        selectedPlural = storedPlural

        if let matchedOption = Self.predefinedOptions.first(where: {
            $0.singular.caseInsensitiveCompare(storedSingular) == .orderedSame &&
                $0.plural.caseInsensitiveCompare(storedPlural) == .orderedSame
        }) {
            selectedOptionID = matchedOption.id
            freeTextSingular = ""
            freeTextPlural = ""
        } else {
            selectedOptionID = Self.freeTextOption.id
            freeTextSingular = storedSingular
            freeTextPlural = storedPlural
        }
    }

    /// Applies one selected terminology option.
    ///
    /// - Parameter optionID: The selected option identifier.
    func selectOption(id optionID: String) {
        guard let option = allOptions.first(where: { $0.id == optionID }) else {
            return
        }

        selectedOptionID = option.id
        guard option.isFreeText == false else {
            selectedSingular = freeTextSingular
            selectedPlural = freeTextPlural
            return
        }

        selectedSingular = option.singular
        selectedPlural = option.plural
    }

    /// Saves terminology values to persistent configuration.
    ///
    /// - Parameter context: The managed object context used for saving.
    func save(context: NSManagedObjectContext) {
        persist(context: context, showsSuccessAlert: true)
    }

    /// Saves terminology values without showing a success alert.
    ///
    /// - Parameter context: The managed object context used for saving.
    func saveSilently(context: NSManagedObjectContext) {
        persist(context: context, showsSuccessAlert: false)
    }

    /// Saves values from the top-trailing checkmark action.
    ///
    /// In free-text mode, both singular and plural values are required.
    /// When one is missing, an alert message is shown and nothing is saved.
    ///
    /// - Parameter context: The managed object context used for saving.
    func saveFromToolbar(context: NSManagedObjectContext) {
        guard isFreeTextSelection else {
            saveSilently(context: context)
            return
        }

        guard hasInvalidFreeTextValues == false else {
            statusMessage = L10n.managementTerminologyErrorBothRequired
            showsStatusAlert = true
            return
        }

        saveSilently(context: context)
    }

    /// Clears the free-text singular value and persists immediately.
    ///
    /// - Parameter context: The managed object context used for saving.
    func clearFreeTextSingular(context: NSManagedObjectContext) {
        guard isFreeTextSelection else {
            return
        }
        selectedSingular = ""
        freeTextSingular = ""
        saveSilently(context: context)
    }

    /// Clears the free-text plural value and persists immediately.
    ///
    /// - Parameter context: The managed object context used for saving.
    func clearFreeTextPlural(context: NSManagedObjectContext) {
        guard isFreeTextSelection else {
            return
        }
        selectedPlural = ""
        freeTextPlural = ""
        saveSilently(context: context)
    }

    /// Saves free-text values for leave confirmation flow.
    ///
    /// - Parameter context: The managed object context used for saving.
    /// - Returns: `true` when save succeeded; otherwise `false`.
    func saveFreeTextForLeaving(context: NSManagedObjectContext) -> Bool {
        guard isFreeTextSelection else {
            return true
        }
        guard hasInvalidFreeTextValues == false else {
            statusMessage = L10n.managementTerminologyErrorBothRequired
            showsStatusAlert = true
            return false
        }
        saveSilently(context: context)
        return true
    }
}

private extension TerminologySettingsViewModel {
    /// Persists terminology values with optional success feedback.
    ///
    /// - Parameters:
    ///   - context: The managed object context used for saving.
    ///   - showsSuccessAlert: Indicates whether successful saves should show an alert.
    func persist(context: NSManagedObjectContext, showsSuccessAlert: Bool) {
        let singular = normalizedName(selectedSingular)
        let plural = normalizedName(selectedPlural)

        guard singular.isEmpty == false else {
            if showsSuccessAlert {
                statusMessage = L10n.managementTerminologyErrorNameRequired
                showsStatusAlert = true
            }
            return
        }

        let resolvedPlural = plural.isEmpty ? singular : plural

        do {
            try configurationService.setValue(singular, for: .counterpartyLabelSingular, profile: profile, context: context)
            try configurationService.setValue(resolvedPlural, for: .counterpartyLabelPlural, profile: profile, context: context)
        } catch {
            statusMessage = L10n.managementTerminologyErrorSaveFailed
            showsStatusAlert = true
            return
        }

        settingsStorage.sharedCounterpartyLabelSingular = singular
        selectedSingular = singular
        selectedPlural = resolvedPlural
        if isFreeTextSelection {
            freeTextSingular = singular
            freeTextPlural = resolvedPlural
        }

        guard showsSuccessAlert else {
            return
        }
        statusMessage = L10n.managementTerminologySaved
        showsStatusAlert = true
    }

    /// Normalizes a free-text name by trimming whitespace.
    ///
    /// - Parameter value: The raw user input.
    /// - Returns: The trimmed value.
    func normalizedName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Reads one configuration value for the active scope.
    ///
    /// - Parameters:
    ///   - key: The configuration key to resolve.
    ///   - context: The managed object context used for loading.
    /// - Returns: The resolved value when available.
    func readValue(_ key: ConfigurationKey, context: NSManagedObjectContext) -> String? {
        do {
            return try configurationService.value(for: key, profile: profile, context: context)
        } catch {
            return nil
        }
    }
}
