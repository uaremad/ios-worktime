//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Observation
import SwiftUI

#if os(iOS)
import UIKit

public typealias ImpactFeedbackStyle = UIImpactFeedbackGenerator.FeedbackStyle
#elseif os(macOS)
/// Defines the intensity style for haptic feedback on macOS.
///
/// - Note: macOS does not support haptic feedback, so this is a placeholder enum.
public enum ImpactFeedbackStyle {
    case light
    case medium
    case heavy
}
#endif

/// Manages haptic impact feedback and user preferences for enabling or disabling it.
///
/// This manager provides centralized control over haptic feedback throughout the app.
/// User preferences are persisted in `UserDefaults` and synchronized across app launches.
///
/// - Important: This class uses the singleton pattern. Access it via `ImpactManager.shared`.
/// - Note: Haptic feedback only works on iOS devices with haptic capabilities.
@MainActor
@Observable
public final class ImpactManager {
    private enum Key {
        static let disabledImpact = "disabled_impact"
        static let suiteName = "ImpactManager"
    }

    /// The shared singleton instance of ImpactManager.
    public static let shared = ImpactManager()

    /// Returns the UserDefaults instance for storing impact preferences.
    private static var defaults: UserDefaults {
        if let defaults = UserDefaults(suiteName: Key.suiteName) {
            return defaults
        }
        return .standard
    }

    /// Indicates whether impact feedback is currently enabled.
    ///
    /// This property reflects the user's preference and is automatically
    /// persisted across app launches.
    public private(set) var isImpactEnabled: Bool

    private init() {
        // Load preference from UserDefaults
        let disabled = Self.defaults.bool(forKey: Key.disabledImpact)
        isImpactEnabled = !disabled
    }

    /// Updates the impact feedback enabled state and persists the preference.
    ///
    /// - Parameter isEnabled: Whether impact feedback should be enabled.
    public func setImpactEnabled(_ isEnabled: Bool) {
        isImpactEnabled = isEnabled
        Self.defaults.set(!isEnabled, forKey: Key.disabledImpact)
    }

    /// Generates haptic impact feedback if enabled by the user.
    ///
    /// This method checks the user's preference before triggering feedback.
    /// On iOS, it uses `UIImpactFeedbackGenerator` to generate the haptic response.
    /// On macOS, this method has no effect as haptic feedback is not supported.
    ///
    /// - Parameter style: The intensity of the haptic feedback. Defaults to `.medium`.
    ///
    /// # Example
    /// ```swift
    /// // Trigger medium impact
    /// ImpactManager.generateImpactFeedback()
    ///
    /// // Trigger heavy impact
    /// ImpactManager.generateImpactFeedback(.heavy)
    /// ```
    public static func generateImpactFeedback(_ style: ImpactFeedbackStyle = .medium) {
        #if os(iOS)
        guard ImpactManager.shared.isImpactEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
        #elseif os(macOS)
        // No haptic feedback support on macOS
        return
        #endif
    }
}
