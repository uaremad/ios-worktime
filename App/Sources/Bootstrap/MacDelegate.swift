//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if os(macOS)
import AppKit
import CoreData
import CoreDataKit
import SwiftUI

/// The main entry point for the macOS application.
///
/// This class provides a pure AppKit application delegate that creates
/// and manages a native NSWindow with SwiftUI content.
@main
@MainActor
final class MacDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    // MARK: - Window

    var window: NSWindow?
    var prefs = PreferencesModel()
    var prefsView: PreferencesView?
    /// The preferences window controller.
    private var preferencesController: PreferencesWindowController?
    /// The observer token used to react to language preference changes.
    private var languagePreferencesObserver: NSObjectProtocol?
    /// The Core Data stack manager used by the macOS app.
    private let coreDataStackManager: CoreDataManager = {
        let configurationProvider = CoreDataStoreConfigurationProvider()
        let isICloudEnabled = SettingsStorageService.shared.isICloudSyncEnabled
        let databaseName = configurationProvider.databaseName(isICloudEnabled: isICloudEnabled)
        let syncMode: CloudSyncMode = if isICloudEnabled {
            .container(
                containerID: configurationProvider.cloudContainerIdentifier,
                scope: .private
            )
        } else {
            .none
        }
        return CoreDataManager(
            bundle: Bundle.main,
            nameModel: "Worktime",
            databaseName: databaseName,
            databaseStorage: .libraryDirectory(appending: "Private Documents"),
            iCloudSyncMode: syncMode
        )
    }()

    // MARK: - Push Notifications

    func application(
        _: NSApplication,
        didRegisterForRemoteNotificationsWithDeviceToken _: Data
    ) {}

    func application(
        _: NSApplication,
        didFailToRegisterForRemoteNotificationsWithError _: Error
    ) {}

    // MARK: - Lifecycle

    func applicationWillFinishLaunching(_: Foundation.Notification) {
        NSApp.setActivationPolicy(.regular)
        print("MacDelegate: applicationWillFinishLaunching — activation policy set")
    }

    func applicationDidFinishLaunching(_: Foundation.Notification) {
        LocalPeerSyncCoordinator.configureShared(container: coreDataStackManager.persistentContainer)

        createMainWindow()
        NSApp.activate(ignoringOtherApps: true)

        // Localize menu items
        localizeMenuItems()
        observeLanguagePreferenceChanges()
    }

    func applicationDidBecomeActive(_: Foundation.Notification) {
        // Re-localize menus after they might have been reset
        localizeMenuItems()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        true
    }

    deinit {
        if let languagePreferencesObserver {
            NotificationCenter.default.removeObserver(languagePreferencesObserver)
        }
    }

    // MARK: - Window Management

    private func createMainWindow() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            return
        }

        let minWidth: CGFloat = 1280
        let minHeight: CGFloat = 800

        let contentView = AppLanguageAwareRootView()
            .environment(\.managedObjectContext, coreDataStackManager.persistentContainer.viewContext)
            .frame(minWidth: minWidth, minHeight: minHeight)

        // Create and configure the main window deterministically.
        let mainWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: minWidth, height: minHeight),
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable,
                .fullSizeContentView
            ],
            backing: .buffered,
            defer: false
        )
        mainWindow.center()
        mainWindow.setFrameAutosaveName("Main Window")
        mainWindow.toolbar?.isVisible = false
        mainWindow.titleVisibility = .hidden
        mainWindow.titlebarAppearsTransparent = true
        mainWindow.backgroundColor = .aBackground
        mainWindow.isOpaque = true
        mainWindow.isReleasedWhenClosed = false
        mainWindow.contentViewController = NSHostingController(rootView: contentView)

        window = mainWindow
        mainWindow.makeKeyAndOrderFront(nil)
        mainWindow.orderFrontRegardless()

        print("MacDelegate: Main window created")
    }

    // MARK: - MainMenu.xib

    @IBAction func openPrefsWindow(_: Any) {
        // Create controller if it doesn't exist
        if preferencesController == nil {
            preferencesController = PreferencesWindowController(
                preferences: prefs,
                deeplink: .settings,
                managedObjectContext: coreDataStackManager.persistentContainer.viewContext
            )
        }

        // Show the window (controller handles whether to create new or bring to front)
        preferencesController?.showWindow()
    }

    // MARK: - Menu Actions

    /// Handles all main menu item actions based on identifier.
    ///
    /// This centralized handler routes menu actions using the menu item's identifier,
    /// eliminating the need for multiple separate IBAction methods.
    ///
    /// - Parameter sender: The menu item that triggered the action.
    @IBAction func handleMenuItem(_ sender: NSMenuItem) {
        if sender.identifier?.rawValue == "add-measurement-menu" {
            print("MacDelegate: Menu selected: measurementInputRequested")
            NotificationManager.measurementInputRequested.postNotification()
            return
        }

        guard
            let identifier = sender.identifier?.rawValue,
            let selection = menuSelection(for: identifier)
        else {
            print("MacDelegate: Unknown menu item: \(sender.identifier?.rawValue ?? "nil")")
            return
        }

        print("MacDelegate: Menu selected: \(selection.rawValue)")
        NotificationManager.menuSelectionChanged(selection: selection).postNotification()
    }

    // MARK: - Menu Localization

    /// Localizes all menu items after the XIB is loaded.
    private func localizeMenuItems() {
        guard let mainMenu = NSApplication.shared.mainMenu else {
            print("MacDelegate: Main menu not found")
            return
        }

        let appName =
            (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
                ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                ?? "App"

        localizeAppleMenu(in: mainMenu, appName: appName)
        localizeNavigationMenu(in: mainMenu)
        localizeEditMenu(in: mainMenu)
    }

    /// Observes language preference changes and refreshes menu localization.
    private func observeLanguagePreferenceChanges() {
        languagePreferencesObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.localizeMenuItems()
            }
        }
    }

    /// Localizes the Apple menu (application menu).
    ///
    /// - Parameters:
    ///   - mainMenu: The application's main menu.
    ///   - appName: The application name from the bundle.
    private func localizeAppleMenu(in mainMenu: NSMenu, appName: String) {
        guard let appleMenuItem = mainMenu.items.first(where: {
            $0.identifier?.rawValue == "app-menu"
        }),
            let appleSubmenu = appleMenuItem.submenu
        else {
            print("MacDelegate: Apple menu NOT found")
            return
        }

        // Set app name as title (standard for macOS Apple menu)
        appleMenuItem.title = appName
        appleSubmenu.title = appName

        // Localize submenu items
        localizeAppleMenuItems(appleSubmenu.items, appName: appName)
    }

    /// Localizes items in the Apple menu.
    ///
    /// - Parameters:
    ///   - items: The menu items to localize.
    ///   - appName: The application name for parameterized strings.
    private func localizeAppleMenuItems(_ items: [NSMenuItem], appName: String) {
        for item in items {
            switch item.identifier?.rawValue {
            case "about-menu":
                item.title = L10n.generalMenuAboutApp(appName)
            case "preferences-menu":
                item.title = L10n.generalMenuPreferences
            case "hide-app-menu":
                item.title = L10n.generalMenuHideApp(appName)
            case "hide-others-menu":
                item.title = L10n.generalMenuHideOthers
            case "show-all-menu":
                item.title = L10n.generalMenuShowAll
            case "quit-menu":
                item.title = L10n.generalMenuQuit(appName)
            default:
                break
            }
        }
    }

    /// Localizes the main navigation menu.
    ///
    /// - Parameter mainMenu: The application's main menu.
    private func localizeNavigationMenu(in mainMenu: NSMenu) {
        guard let mainMenuItem = mainMenu.items.first(where: {
            $0.identifier?.rawValue == "mainmenu-menu"
        }),
            let mainSubmenu = mainMenuItem.submenu
        else {
            print("MacDelegate: Main navigation menu NOT found")
            return
        }

        // Localize the parent menu item title
        mainMenuItem.title = L10n.generalMenuMain
        mainSubmenu.title = L10n.generalMenuMain

        // Localize submenu items
        localizeNavigationMenuItems(mainSubmenu.items)
        ensureMenuDivider(in: mainSubmenu, beforeItemIdentifier: "add-measurement-menu")
    }

    /// Localizes the Edit menu (standard editing commands).
    ///
    /// - Parameter mainMenu: The application's main menu.
    private func localizeEditMenu(in mainMenu: NSMenu) {
        guard let editMenuIndex = mainMenu.items.firstIndex(where: {
            $0.identifier?.rawValue == "edit-menu"
        }) else {
            return
        }

        mainMenu.removeItem(at: editMenuIndex)
    }

    /// Localizes items in the main navigation menu.
    ///
    /// - Parameter items: The menu items to localize.
    private func localizeNavigationMenuItems(_ items: [NSMenuItem]) {
        for item in items {
            if item.identifier?.rawValue == "add-measurement-menu" {
                item.title = L10n.generalMeasurementAdd
                item.image = configuredMenuImage(systemName: "plus")
                item.keyEquivalent = "n"
                item.keyEquivalentModifierMask = [.command]
                continue
            }

            guard
                let identifier = item.identifier?.rawValue,
                let selection = menuSelection(for: identifier)
            else {
                continue
            }

            item.title = menuTitle(for: selection)
            item.image = configuredMenuImage(systemName: menuSystemImageName(for: selection))
            item.keyEquivalent = ""
            item.keyEquivalentModifierMask = []
        }
    }

    /// Ensures one separator item is present directly before a specific menu item.
    ///
    /// - Parameters:
    ///   - menu: The navigation submenu that should contain a separator.
    ///   - beforeItemIdentifier: The identifier of the menu item below the separator.
    private func ensureMenuDivider(in menu: NSMenu, beforeItemIdentifier: String) {
        guard let targetIndex = menu.items.firstIndex(where: { $0.identifier?.rawValue == beforeItemIdentifier }) else {
            return
        }

        if targetIndex > 0, menu.items[targetIndex - 1].isSeparatorItem {
            return
        }

        menu.insertItem(.separator(), at: targetIndex)
    }

    /// Maps one menu item identifier to the app's sidebar menu selection.
    ///
    /// - Parameter identifier: The menu identifier from the main menu.
    /// - Returns: The mapped `MenuSelection`, or `nil` if unsupported.
    private func menuSelection(for identifier: String) -> MenuSelection? {
        switch identifier {
        case "search-menu":
            .overview
        case "collection-menu":
            .values
        case "deck-menu":
            .reportPie
        case "bookmark-menu":
            .reportLine
        case "tags-menu":
            .reportBar
        case "releases-menu":
            .data
        default:
            nil
        }
    }

    /// Resolves the localized menu title for one sidebar menu selection.
    ///
    /// - Parameter selection: The target sidebar menu selection.
    /// - Returns: A localized menu item title.
    private func menuTitle(for selection: MenuSelection) -> String {
        switch selection {
        case .overview:
            L10n.generalTabOverview
        case .values:
            L10n.generalTabOverview
        case .reportPie:
            L10n.generalTabOverview
        case .reportLine:
            L10n.generalTabOverview
        case .reportBar:
            L10n.generalTabOverview
        case .data:
            L10n.generalTabData
        }
    }

    /// Resolves the SF Symbol name for one sidebar menu selection.
    ///
    /// - Parameter selection: The target sidebar menu selection.
    /// - Returns: The SF Symbol name shown in the menu.
    private func menuSystemImageName(for selection: MenuSelection) -> String {
        switch selection {
        case .overview:
            TabItem.Tab.summary.icon()
        case .values:
            TabItem.Tab.values.icon()
        case .reportPie:
            "chart.pie"
        case .reportLine:
            "chart.xyaxis.line"
        case .reportBar:
            "chart.bar"
        case .data:
            "internaldrive"
        }
    }

    /// Creates one configured NSMenu image from an SF Symbol name.
    ///
    /// - Parameter systemName: The SF Symbol identifier to render.
    /// - Returns: A template image configured for menu rendering.
    private func configuredMenuImage(systemName: String) -> NSImage {
        let image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil) ?? NSImage()
        image.size = NSSize(width: 12, height: 12)
        image.isTemplate = true
        return image
    }
}

extension MacDelegate {
    /// Handles files opened via Finder, Dock, or AirDrop.
    ///
    /// - Parameters:
    ///   - application: The running application instance.
    ///   - urls: The incoming file URLs.
    func application(_: NSApplication, open _: [URL]) {}

    /// Presents a generic import error alert.
    ///
    /// - Parameter error: The import error to display.
    private func presentImportErrorAlert(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = L10n.errorBackupExportTitle
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.generalOk)
        alert.runModal()
    }
}

/// Hosts the main app content and applies the live app-language override.
@MainActor
private struct AppLanguageAwareRootView: View {
    /// Stores the app language override code.
    @AppStorage("appLanguageOverrideCode") private var appLanguageOverrideCode: String = "system"

    /// Renders the main app content with localized environment.
    var body: some View {
        ZStack {
            Color.aBackground
            Bootstrap()
        }
        .id(appLanguageOverrideCode)
        .environment(\.locale, appLocale)
        .environment(\.layoutDirection, appLayoutDirection)
    }

    /// Resolves the effective locale from persisted app-language override.
    private var appLocale: Locale {
        if appLanguageOverrideCode == "system" {
            return .current
        }
        return Locale(identifier: appLanguageOverrideCode)
    }

    /// Resolves the global layout direction for the app content.
    private var appLayoutDirection: LayoutDirection {
        effectiveLanguageCode == "ar" ? .rightToLeft : .leftToRight
    }

    /// Resolves the effective language code used by locale and layout.
    private var effectiveLanguageCode: String {
        if appLanguageOverrideCode == "system" {
            guard let firstPreferred = Locale.preferredLanguages.first else {
                return "en"
            }
            return normalizedLanguageCode(from: firstPreferred)
        }
        return normalizedLanguageCode(from: appLanguageOverrideCode)
    }

    /// Normalizes locale identifiers to their primary language code.
    ///
    /// - Parameter identifier: The locale identifier to normalize.
    /// - Returns: The primary language code or `"en"` as fallback.
    private func normalizedLanguageCode(from identifier: String) -> String {
        let parts = identifier.split(whereSeparator: { $0 == "-" || $0 == "_" })
        guard let primary = parts.first, primary.isEmpty == false else {
            return "en"
        }
        return String(primary)
    }
}
#endif
