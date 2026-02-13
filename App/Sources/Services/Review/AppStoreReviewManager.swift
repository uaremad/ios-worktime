//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

import StoreKit

/// Manages when and how the app prompts users to leave a review in the App Store.
///
/// This manager tracks the number of app launches and the time since the first launch
/// or last review to decide if a review request should be made.
///
/// ## Usage Example
///
/// ```swift
/// // In your app delegate or main entry point
/// Task {
///     await AppStoreReviewManager.requestIf(launches: 10, days: 7)
/// }
/// ```
///
/// - Important: Review requests are automatically throttled by the system.
/// - Note: All operations run on the main actor for thread safety.
@MainActor
public final class AppStoreReviewManager {
    // MARK: - Configuration

    /// The minimum number of launches required before considering a review request.
    public let minLaunches: Int

    /// The minimum number of days after the first launch required before considering a review request.
    public let minDays: Int

    /// The minimum number of days between review requests.
    private let minDaysBetweenReviews: Int = 125

    // MARK: - Version Information

    /// The current version of the app.
    private let currentVersion: String?

    /// The version number of the app's first release, used to bypass review requirements.
    private let firstReleaseVersion: String = "1.0.0"

    // MARK: - Storage

    /// A reference to the UserDefaults storage.
    private let userDefaults: UserDefaults

    // MARK: - UserDefaults Keys

    private enum StorageKey {
        static let launches = "AppStoreReviewManagerLaunches"
        static let firstLaunchDate = "AppStoreReviewManagerFirstLaunchDate"
        static let lastReviewDate = "AppStoreReviewManagerLastReviewDate"
        static let lastReviewVersion = "AppStoreReviewManagerLastReviewVersion"
    }

    // MARK: - Initialization

    /// Creates a new AppStoreReviewManager with the specified minimum launches and days.
    ///
    /// - Parameters:
    ///   - minLaunches: The minimum number of launches required before considering a review request.
    ///   - minDays: The minimum number of days after the first launch required before considering a review request.
    ///   - userDefaults: The UserDefaults instance to use for storage. Defaults to `.standard`.
    public init(
        minLaunches: Int = 5,
        minDays: Int = 0,
        userDefaults: UserDefaults = .standard
    ) {
        self.minLaunches = minLaunches
        self.minDays = minDays
        self.userDefaults = userDefaults
        currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    // MARK: - Public API

    /// Opens the App Store review page for the app manually.
    ///
    /// This method opens the user's default browser to the App Store review page,
    /// allowing them to write a review directly.
    ///
    /// - Important: Ensure `AppConfiguration.appStoreId` is properly configured.
    public static func requestReviewManually() async {
        let appStoreId = AppInfo().appstoreId
        guard appStoreId.isEmpty == false, appStoreId.allSatisfy(\.isNumber) else {
            return
        }
        guard let reviewURL = URL(
            string: "https://apps.apple.com/app/id\(appStoreId)?action=write-review"
        ) else {
            return
        }

        #if os(macOS)
        NSWorkspace.shared.open(reviewURL)
        #elseif os(iOS)
        await UIApplication.shared.open(reviewURL)
        #endif
    }

    /// Requests a review if the conditions specified by the launches and days parameters are met.
    ///
    /// This is a convenience method that creates a manager instance and immediately
    /// checks if a review request should be made.
    ///
    /// - Parameters:
    ///   - launches: The number of launches to compare against the minimum required launches.
    ///   - days: The number of days since the first launch to compare against the minimum required days.
    /// - Returns: A boolean value indicating whether the review request was made.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Task {
    ///     await AppStoreReviewManager.requestIf(launches: 10, days: 7)
    /// }
    /// ```
    @discardableResult
    public static func requestIf(launches: Int = 5, days: Int = 0) async -> Bool {
        let manager = AppStoreReviewManager(minLaunches: launches, minDays: days)
        return await manager.requestIfNeeded()
    }

    /// Checks if a review request is needed and performs the request if necessary.
    ///
    /// This method:
    /// 1. Records the current launch
    /// 2. Checks if conditions are met for a review request
    /// 3. Performs the review request if needed
    /// 4. Updates the last review date and version
    ///
    /// - Returns: A boolean value indicating whether the review request was made.
    @discardableResult
    public func requestIfNeeded() async -> Bool {
        // Initialize first launch date if needed
        if firstLaunchDate == nil {
            firstLaunchDate = Date()
        }

        // Increment launch count
        launches += 1

        // Check if review is needed
        guard isNeeded else {
            return false
        }

        // Update review tracking
        lastReviewDate = Date()
        lastReviewVersion = currentVersion

        // Request review
        await request()

        return true
    }

    // MARK: - Computed Properties

    /// The number of app launches, stored in UserDefaults.
    public var launches: Int {
        get {
            userDefaults.integer(forKey: StorageKey.launches)
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.launches)
        }
    }

    /// The date of the app's first launch, stored in UserDefaults.
    public var firstLaunchDate: Date? {
        get {
            userDefaults.object(forKey: StorageKey.firstLaunchDate) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.firstLaunchDate)
        }
    }

    /// The date of the last review request, stored in UserDefaults.
    public var lastReviewDate: Date? {
        get {
            userDefaults.object(forKey: StorageKey.lastReviewDate) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.lastReviewDate)
        }
    }

    /// The version of the app at the time of the last review request, stored in UserDefaults.
    public var lastReviewVersion: String? {
        get {
            userDefaults.string(forKey: StorageKey.lastReviewVersion)
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.lastReviewVersion)
        }
    }

    /// The number of days since the app's first launch.
    ///
    /// - Returns: The number of days, or 0 if the first launch date is not set.
    public var daysAfterFirstLaunch: Int {
        guard let firstLaunch = firstLaunchDate else {
            return 0
        }
        return daysBetween(firstLaunch, Date())
    }

    /// The number of days since the last review request.
    ///
    /// - Returns: The number of days, or 0 if no review has been requested yet.
    public var daysAfterLastReview: Int {
        guard let lastReview = lastReviewDate else {
            return 0
        }
        return daysBetween(lastReview, Date())
    }

    /// Determines if a review request is needed based on launch counts, time since the first launch,
    /// and time since the last review.
    ///
    /// Review is needed when:
    /// - Launch count meets minimum requirement
    /// - Days since first launch meets minimum requirement
    /// - Either no previous review OR sufficient time has passed since last review
    /// - Version has changed since last review (except for first release version)
    public var isNeeded: Bool {
        // Check minimum launches
        guard launches >= minLaunches else {
            return false
        }

        // Check minimum days after first launch
        guard daysAfterFirstLaunch >= minDays else {
            return false
        }

        // Check time since last review
        if lastReviewDate != nil {
            guard daysAfterLastReview >= minDaysBetweenReviews else {
                return false
            }
        }

        // Check version requirements
        let isFirstRelease = currentVersion == firstReleaseVersion
        let versionChanged = lastReviewVersion != currentVersion

        return isFirstRelease || versionChanged
    }

    // MARK: - Private Methods

    /// Performs the review request by showing the system review prompt.
    ///
    /// The request is delayed by 1 second to ensure proper UI presentation.
    /// The system may choose not to show the prompt based on its own throttling logic.
    private func request() async {
        // Delay to ensure proper UI presentation
        try? await Task.sleep(for: .seconds(1))

        #if os(iOS)
        // Use new AppStore API for iOS 18.0+
        if #available(iOS 18.0, *) {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                return
            }
            AppStore.requestReview(in: scene)
        } else {
            // Fallback for older iOS versions
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                return
            }
            SKStoreReviewController.requestReview(in: scene)
        }

        #elseif os(macOS)
        // Use new AppStore API for macOS 15.0+
        if #available(macOS 15.0, *) {
            // Get the content view controller from the key window
            guard let window = NSApplication.shared.keyWindow,
                  let viewController = window.contentViewController
            else {
                return
            }
            AppStore.requestReview(in: viewController)
        } else {
            // Fallback for older macOS versions
            SKStoreReviewController.requestReview()
        }
        #endif
    }

    /// Calculates the number of days between two dates.
    ///
    /// - Parameters:
    ///   - start: The start date.
    ///   - end: The end date.
    /// - Returns: The number of days between the two dates, or 0 if calculation fails.
    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        guard let days = Calendar.current.dateComponents([.day], from: start, to: end).day else {
            return 0
        }
        return days
    }
}

// MARK: - Testing Support

public extension AppStoreReviewManager {
    /// Resets all stored review data for testing purposes.
    ///
    /// - Warning: This should only be used for testing. Do not call in production code.
    func resetForTesting() {
        userDefaults.removeObject(forKey: StorageKey.launches)
        userDefaults.removeObject(forKey: StorageKey.firstLaunchDate)
        userDefaults.removeObject(forKey: StorageKey.lastReviewDate)
        userDefaults.removeObject(forKey: StorageKey.lastReviewVersion)
    }
}
