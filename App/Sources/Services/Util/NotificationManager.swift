//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

/// A protocol that defines a notification descriptor.
public protocol NotificationDescriptor {
    /// The name of the notification.
    static var name: Foundation.Notification.Name { get }
}

public extension NotificationDescriptor {
    /// The default implementation of `name`, which returns a `Notification.Name`
    /// object with the same name as the descriptor's type.
    static var name: Foundation.Notification.Name {
        Foundation.Notification.Name(String(describing: self))
    }
}

/// Represents available menu destinations for macOS main menu routing.
public enum MenuSelection: String, Sendable {
    /// Opens the overview module.
    case overview

    /// Opens the values list module.
    case values

    /// Opens the report summary (pie chart) module.
    case reportPie

    /// Opens the report trend (line chart) module.
    case reportLine

    /// Opens the report measurements (bar chart) module.
    case reportBar

    /// Opens the data tools module.
    case data
}

/// NotificationManager is a utility that helps manage notifications and their names in the application.
///
/// Example:
/// ```
/// NotificationManager.errorReport(error: NSError...).postNotification()
/// NotificationManager.collectionOwnershipChange(lookupKeys: ["m11|146", "ktk|23"]).postNotification()
/// ```
public enum NotificationManager {
    case appWillEnterForeground
    case errorReport(error: NSError)
    case menuSelectionChanged(selection: MenuSelection)
    case measurementInputRequested

    /// Computed property to get the corresponding Notification.Name for each case
    private var notificationName: Foundation.Notification.Name {
        switch self {
        case .appWillEnterForeground:
            AppWillEnterForegroundNotification.name
        case .errorReport:
            ErrorReportNotification.name
        case .menuSelectionChanged:
            MenuSelectionDidChangeNotification.name
        case .measurementInputRequested:
            MeasurementInputRequestedNotification.name
        }
    }

    public func postNotification() {
        let notificationCenterDefault = NotificationCenter.default
        let name = notificationName // Use the computed property
        var userInfo: [AnyHashable: Any]? // Optional user info

        switch self {
        case let .errorReport(error):
            userInfo = ["error": error]
        case let .menuSelectionChanged(selection):
            userInfo = [
                "selection": selection.rawValue
            ]
        default:
            break
        }

        let notification = Foundation.Notification(name: name, object: nil, userInfo: userInfo)
        notificationCenterDefault.post(notification)
    }
}

/// A type representing the notification for when the app will enter foreground.
public struct AppWillEnterForegroundNotification: NotificationDescriptor {
    public init() {}
}

/// A type representing the notification for when a shop specified section should open.
public struct ErrorReportNotification: NotificationDescriptor {
    public init() {}
}

/// A type representing the notification for when the menu selection changes (macOS).
public struct MenuSelectionDidChangeNotification: NotificationDescriptor {
    public init() {}
}

/// A type representing the notification for opening the measurement input (macOS).
public struct MeasurementInputRequestedNotification: NotificationDescriptor {
    public init() {}
}
