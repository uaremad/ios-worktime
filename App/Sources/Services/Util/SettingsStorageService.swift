//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

/// Tracks all properties stored on device via persistent storage module (UserDefaults).
public class SettingsStorageService {
    public static let shared = SettingsStorageService()

    private let storage = UserDefaults.standard

    public init() {
        storage.register(defaults: [
            "UseImpactForButton": true,
            "ReportingSelectedTabIndex": 1,
            "SharedDateRangePreset": DateRangePreset.all.rawValue,
            "ReportingShowsDiastolic": true,
            "ReportingShowsPulse": false,
            "ReportingShowsPulsePressure": false,
            "iCloudSyncEnabled": false
        ])
    }

    /// Controls the selected appearance mode.
    public var appearanceSelection: Int {
        get { storage.integer(forKey: "UseDarkmode") }
        set { storage.set(newValue, forKey: "UseDarkmode") }
    }

    /// Controls whether impact feedback is enabled.
    public var isImpactEnabled: Bool {
        get { storage.bool(forKey: "UseImpactForButton") }
        set { storage.set(newValue, forKey: "UseImpactForButton") }
    }

    public var migrationCompleted: Bool {
        get { storage.bool(forKey: "migrationCompleted") }
        set { storage.set(newValue, forKey: "migrationCompleted") }
    }

    /// Stores the selected report tab index.
    public var reportingSelectedTabIndex: Int {
        get { storage.integer(forKey: "ReportingSelectedTabIndex") }
        set { storage.set(newValue, forKey: "ReportingSelectedTabIndex") }
    }

    /// Stores the shared date-range preset for chart and reporting.
    public var sharedDateRangePreset: DateRangePreset {
        get {
            let rawValue = storage.string(forKey: "SharedDateRangePreset") ?? DateRangePreset.all.rawValue
            return DateRangePreset(rawValue: rawValue) ?? .all
        }
        set { storage.set(newValue.rawValue, forKey: "SharedDateRangePreset") }
    }

    /// Stores the shared inclusive start date for chart and reporting.
    public var sharedDateRangeFrom: Date? {
        get { storage.object(forKey: "SharedDateRangeFrom") as? Date }
        set { storage.set(newValue, forKey: "SharedDateRangeFrom") }
    }

    /// Stores the shared inclusive end date for chart and reporting.
    public var sharedDateRangeTo: Date? {
        get { storage.object(forKey: "SharedDateRangeTo") as? Date }
        set { storage.set(newValue, forKey: "SharedDateRangeTo") }
    }

    /// Controls whether the reporting chart shows the diastolic series.
    public var isReportingDiastolicVisible: Bool {
        get { storage.bool(forKey: "ReportingShowsDiastolic") }
        set { storage.set(newValue, forKey: "ReportingShowsDiastolic") }
    }

    /// Controls whether the reporting chart shows the pulse series.
    public var isReportingPulseVisible: Bool {
        get { storage.bool(forKey: "ReportingShowsPulse") }
        set { storage.set(newValue, forKey: "ReportingShowsPulse") }
    }

    /// Controls whether the reporting chart shows the pulse pressure series.
    public var isReportingPulsePressureVisible: Bool {
        get { storage.bool(forKey: "ReportingShowsPulsePressure") }
        set { storage.set(newValue, forKey: "ReportingShowsPulsePressure") }
    }

    /// Controls whether iCloud synchronization is enabled for Core Data.
    public var isICloudSyncEnabled: Bool {
        get { storage.bool(forKey: "iCloudSyncEnabled") }
        set { storage.set(newValue, forKey: "iCloudSyncEnabled") }
    }

    /// Stores the optional active profile object URI used for scoped dashboards.
    public var activeProfileObjectURI: String {
        get { storage.string(forKey: "ActiveProfileObjectURI") ?? "" }
        set { storage.set(newValue, forKey: "ActiveProfileObjectURI") }
    }

    /// Stores the shared singular counterparty terminology label for quick UI reuse.
    public var sharedCounterpartyLabelSingular: String {
        get { storage.string(forKey: "SharedCounterpartyLabelSingular") ?? "" }
        set { storage.set(newValue, forKey: "SharedCounterpartyLabelSingular") }
    }
}
