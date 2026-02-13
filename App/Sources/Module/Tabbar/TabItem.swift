//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

/// A struct representing an item in the tab bar.
public struct TabItem: Equatable, Identifiable {
    /// An enum defining the possible tabs in the application.
    public enum Tab: String {
        case bootstrap
        case summary
        case report
        case start
        case values
        case export
        case management

        /// Returns the system name of the icon associated with the tab.
        ///
        /// - Parameter selected: A boolean indicating whether the tab is currently selected.
        /// - Returns: The system name of the tab's icon.
        func icon(selected: Bool = false) -> String {
            switch self {
            case .bootstrap: selected ? "house.fill" : "house"
            case .summary: selected ? "list.bullet.rectangle.fill" : "list.bullet.rectangle"
            case .report: selected ? "doc.text.fill" : "doc.text"
            case .start: selected ? "heart.fill" : "heart"
            case .values: selected ? "folder.fill" : "folder"
            case .export: selected ? "gearshape.fill" : "gearshape"
            case .management: selected ? "folder.fill" : "folder"
            }
        }
    }

    /// The unique identifier of the tab item.
    public var id: UUID = .init()

    /// The tab associated with the tab item.
    public var tab: Tab

    /// Initializes a new tab item with the specified tab.
    ///
    /// - Parameter tab: The tab associated with the tab item.
    public init(tab: Tab) {
        self.tab = tab
    }
}
