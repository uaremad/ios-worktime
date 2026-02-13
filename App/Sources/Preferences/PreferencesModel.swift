//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if os(macOS)
import AppKit
import Foundation
import SwiftUI

/// Manages application preferences and user settings.
///
/// This model handles persistent storage of user preferences using UserDefaults
/// and provides reactive updates through the Observable protocol.
///
/// ## Usage Example
///
/// ```swift
/// @State private var preferences = PreferencesModel()
///
/// var body: some View {
///     Toggle("Show Line Numbers", isOn: $preferences.showLineNumbers)
/// }
/// ```
///
/// - Important: This class requires macOS and uses AppKit for appearance management.
/// - Note: All operations run on the main actor for thread safety.
@MainActor
@Observable
public final class PreferencesModel {
    // MARK: - Storage Keys

    /// UserDefaults keys for persistent storage.
    private enum StorageKey {
        /// The primary key for appearance mode selection.
        static let appearanceSelection = "appearanceSelection"

        /// The legacy appearance selection key from previous versions.
        static let legacyAppearanceSelection = "UseDarkmode"

        /// The legacy string key used by earlier macOS preferences.
        static let legacySystemMode = "system_mode"
    }

    // MARK: - Appearance Mode

    /// Represents the application's appearance mode.
    public enum AppearanceMode: Int, Sendable {
        case system = 0
        case light = 1
        case dark = 2

        /// The corresponding UserDefaults string value.
        var storageValue: String {
            switch self {
            case .system: "system"
            case .light: "light"
            case .dark: "dark"
            }
        }

        /// The corresponding NSAppearance for this mode.
        var nsAppearance: NSAppearance? {
            switch self {
            case .system: nil
            case .light: NSAppearance(named: .aqua)
            case .dark: NSAppearance(named: .darkAqua)
            }
        }

        /// Creates an appearance mode from a storage string value.
        ///
        /// - Parameter storageValue: The string value from UserDefaults.
        /// - Returns: The corresponding appearance mode, defaulting to `.system` if invalid.
        static func from(storageValue: String) -> AppearanceMode {
            switch storageValue {
            case "light": .light
            case "dark": .dark
            default: .system
            }
        }
    }

    /// The current appearance mode (system, light, or dark).
    ///
    /// Setting this property updates both the UserDefaults storage and
    /// the application's visual appearance.
    public var appearance: AppearanceMode {
        didSet {
            applyAppearance(appearance)
            storeAppearanceSelection(appearance.rawValue)
            changesDetected()
        }
    }

    // MARK: - Storage

    /// The UserDefaults instance used for persistent storage.
    private let userDefaults: UserDefaults

    // MARK: - Initialization

    /// Creates a new preferences model with values loaded from UserDefaults.
    ///
    /// If no value exists for a preference, sensible defaults are used:
    /// - `showLineNumbers`: `true`
    /// - `enabledSound`: `false`
    /// - `enabledAlert`: `false`
    /// - `enabledSelfTest`: `false`
    /// - `appearance`: `.system`
    ///
    /// - Parameter userDefaults: The UserDefaults instance to use. Defaults to `.standard`.
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Load appearance mode
        let selection = Self.loadAppearanceSelection(from: userDefaults)
        appearance = AppearanceMode(rawValue: selection) ?? .system

        // Apply initial appearance
        applyAppearance(appearance)
    }

    // MARK: - Private Methods

    /// Applies the specified appearance mode to the application.
    ///
    /// This method updates NSApp's appearance property on the main actor.
    ///
    /// - Parameter mode: The appearance mode to apply.
    private func applyAppearance(_ mode: AppearanceMode) {
        NSApp.appearance = mode.nsAppearance
    }

    /// Called whenever any preference changes.
    ///
    /// This method can be used to trigger notifications or other side effects
    /// when preferences are updated.
    private func changesDetected() {
        // Future implementation: Post notification for preference changes
        // NotificationCenter.default.post(name: .preferencesChanged, object: self)
    }

    /// Loads the appearance selection from primary and legacy keys.
    ///
    /// - Returns: `0` for system, `1` for light, and `2` for dark.
    private static func loadAppearanceSelection(from userDefaults: UserDefaults) -> Int {
        if userDefaults.object(forKey: StorageKey.appearanceSelection) != nil {
            return userDefaults.integer(forKey: StorageKey.appearanceSelection)
        }

        if userDefaults.object(forKey: StorageKey.legacyAppearanceSelection) != nil {
            return userDefaults.integer(forKey: StorageKey.legacyAppearanceSelection)
        }

        guard let legacySystemMode = userDefaults.string(forKey: StorageKey.legacySystemMode) else {
            return AppearanceMode.system.rawValue
        }

        return AppearanceMode.from(storageValue: legacySystemMode).rawValue
    }

    /// Stores the appearance selection and keeps legacy keys synchronized.
    ///
    /// - Parameter value: The appearance selection value.
    private func storeAppearanceSelection(_ value: Int) {
        userDefaults.set(value, forKey: StorageKey.appearanceSelection)
        userDefaults.set(value, forKey: StorageKey.legacyAppearanceSelection)

        let legacySystemModeValue = AppearanceMode(rawValue: value)?.storageValue ?? AppearanceMode.system.storageValue
        userDefaults.set(legacySystemModeValue, forKey: StorageKey.legacySystemMode)
    }
}

// MARK: - Convenience Accessors

public extension PreferencesModel {
    /// Whether the current appearance is light mode.
    var isLightMode: Bool {
        appearance == .light
    }

    /// Whether the current appearance is dark mode.
    var isDarkMode: Bool {
        appearance == .dark
    }

    /// Whether the current appearance follows system settings.
    var isSystemMode: Bool {
        appearance == .system
    }
}

// MARK: - Reset Support

public extension PreferencesModel {
    /// Resets all preferences to their default values.
    ///
    /// - Warning: This action cannot be undone.
    func resetToDefaults() {
        appearance = .system
    }

    /// Removes all stored preference values from UserDefaults.
    ///
    /// After calling this method, the next initialization will use default values.
    ///
    /// - Warning: This should only be used for testing or troubleshooting.
    func clearStorage() {
        userDefaults.removeObject(forKey: StorageKey.appearanceSelection)
        userDefaults.removeObject(forKey: StorageKey.legacyAppearanceSelection)
        userDefaults.removeObject(forKey: StorageKey.legacySystemMode)
    }
}

// MARK: - Testing Support

#if DEBUG
public extension PreferencesModel {
    /// Creates a preferences model with custom initial values for testing.
    ///
    /// - Parameters:
    ///   - appearance: Initial appearance mode.
    /// - Returns: A configured preferences model.
    static func mock(
        appearance: AppearanceMode = .system
    ) -> PreferencesModel {
        let model = PreferencesModel(userDefaults: .standard)
        model.appearance = appearance
        return model
    }
}
#endif

#endif // os(macOS)
