//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

public extension NavigationStackRoute {
    /// Defines supported filters for the time records list destination.
    enum TimeRecordsListFilter: String, Hashable, Sendable {
        /// Shows all matching records.
        case all
        /// Shows records pending approval.
        case approvalPending
        /// Shows records still open for billing.
        case billingOpen
        /// Shows records invoiced in the current month.
        case invoicedThisMonth
    }

    /// Represents high-level entry points (modules or plugins) within the app.
    ///
    /// This enum is used as the associated value for `.module` in `NavigationStackRoute`
    /// to navigate to major sections like Writing or Settings.
    enum Destination: Hashable, Identifiable {
        /// The overview screen.
        case overview
        /// The reporting statistics screen.
        case reporting
        /// The legal imprint screen.
        case imprint
        /// The privacy policy screen.
        case privacyPolicy
        /// The export data screen.
        case export
        /// The CSV import screen.
        case importData
        /// The reminder settings screen.
        case reminder
        /// The iCloud synchronization settings screen.
        case icloud
        /// The local peer sync introduction screen.
        case peerSyncIntro
        /// The purchases management screen.
        case purchases
        /// The time records list screen.
        case timeRecordsList(filter: TimeRecordsListFilter)
        /// The billing settings screen.
        case billingSettings
        /// The invoicing settings screen.
        case invoicingSettings
        /// The activity settings screen.
        case activitySettings
        /// The terminology settings screen.
        case terminologySettings
        /// The cost-centre settings screen.
        case costCentreSettings

        /// Conforms to `Identifiable` to support use in SwiftUI navigation APIs.
        public var id: Self { self }
    }
}
