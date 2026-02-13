//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if os(macOS)
import CoreData
import SwiftUI

// MARK: - Preferences Window Controller

/// Controls the preferences window and manages its lifecycle.
///
/// This controller acts as its own window delegate to ensure proper
/// cleanup when the window is closed, preventing dangling pointer issues.
/// The controller must be retained for the lifetime of the window.
@MainActor
public final class PreferencesWindowController: NSObject, NSWindowDelegate {
    /// The window displaying the preferences.
    private var window: NSWindow?

    /// The hosting controller managing the SwiftUI content.
    private var hostingController: NSHostingController<AnyView>?

    /// The preferences model.
    private let preferences: PreferencesModel

    /// The initial deeplink menu item.
    private let deeplink: PreferencesView.MenuItem

    /// The managed object context used by debug actions.
    private let managedObjectContext: NSManagedObjectContext

    /// Creates a new preferences window controller.
    ///
    /// - Parameters:
    ///   - preferences: The preferences model to display.
    ///   - deeplink: The initial menu item to display.
    ///   - managedObjectContext: The managed object context used by preferences tools.
    public init(
        preferences: PreferencesModel,
        deeplink: PreferencesView.MenuItem = .settings,
        managedObjectContext: NSManagedObjectContext
    ) {
        self.preferences = preferences
        self.deeplink = deeplink
        self.managedObjectContext = managedObjectContext
        super.init()
    }

    /// Shows the preferences window.
    ///
    /// If the window is already visible, it will be brought to front and deminimized.
    /// Otherwise, a new window is created.
    public func showWindow() {
        // Check if window exists and is visible
        if let window, window.isVisible {
            window.deminiaturize(nil)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create new window
        let newWindow = NSWindow.createStandardWindow(
            withTitle: "Lorem Ipsum",
            width: 860,
            height: 540
        )

        // Keep the window alive deterministically under ARC
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.tabbingMode = .disallowed

        // Create the SwiftUI view
        let rootView = PreferencesView(preferences, deeplink: deeplink)
            .environment(\.managedObjectContext, managedObjectContext)

        // Use contentViewController instead of swapping contentView directly
        let host = NSHostingController(rootView: AnyView(rootView))
        newWindow.contentViewController = host
        hostingController = host

        window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Called when the window is about to close.
    ///
    /// Cleanup is deferred to the next run loop so AppKit and SwiftUI can
    /// finish tearing down the view hierarchy safely.
    ///
    /// - Parameter notification: The notification containing window information.
    public func windowWillClose(_: Foundation.Notification) {
        Task { @MainActor [weak self] in
            await Task.yield()
            guard let self else { return }
            hostingController = nil
            window?.delegate = nil
            window = nil
        }
    }

    /// Closes the preferences window.
    public func closeWindow() {
        window?.close()
    }
}

// MARK: - Preferences View

/// A view that presents the application preferences interface.
///
/// The preferences are displayed using a sidebar navigation with categories
/// such as Appearance, Language, Cloud, and Rating. The selected category's
/// settings are shown in the detail pane.
///
/// ## Usage Example
///
/// ```swift
/// // Use PreferencesWindowController to show the window:
/// let controller = PreferencesWindowController(preferences: preferences)
/// controller.showWindow()
/// ```
///
/// - Important: This view requires macOS and should be presented via PreferencesWindowController.
/// - Note: All operations run on the main actor for thread safety.
@MainActor
public struct PreferencesView: View {
    // MARK: - Menu Items

    /// Represents the different sections available in the preferences window.
    public enum MenuItem: String, CaseIterable, Identifiable, Sendable {
        case settings
        case imprint
        case privacy
        case rateApp
        #if DEBUG
        case developer
        #endif

        /// The localized display name for this menu item.
        public var localizedName: String {
            switch self {
            case .settings:
                L10n.generalMoreSectionSettings
            case .imprint:
                L10n.generalMoreImprint
            case .privacy:
                L10n.generalMorePrivacy
            case .rateApp:
                L10n.generalMoreRateApp
            #if DEBUG
            case .developer:
                L10n.generalMoreSectionDeveloper
            #endif
            }
        }

        /// The unique identifier for this menu item.
        public var id: String { rawValue }
    }

    // MARK: - Properties

    /// The preferences model containing user settings.
    @State var preferences: PreferencesModel

    /// The currently selected menu item in the sidebar.
    @State var selectedMenuItem: MenuItem

    /// The currently selected app language override code.
    @AppStorage("appLanguageOverrideCode") var appLanguageOverrideCode: String = "system"

    /// The managed object context from the preferences window environment.
    @Environment(\.managedObjectContext) var viewContext

    // MARK: - Initialization

    /// Creates a new preferences view.
    ///
    /// - Parameters:
    ///   - preferences: The preferences model to display and modify.
    ///   - deeplink: The initial menu item to display. Defaults to `.appearance`.
    public init(
        _ preferences: PreferencesModel,
        deeplink: MenuItem = .settings
    ) {
        _preferences = State(initialValue: preferences)
        _selectedMenuItem = State(initialValue: deeplink)
    }

    // MARK: - Body

    public var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .id(appLanguageOverrideCode)
        .environment(\.locale, preferencesLocale)
        .frame(minWidth: 800, minHeight: 600)
        .background(Color.aBackground)
        .foregroundStyle(Color.aPrimary)
        .onChange(of: selectedMenuItem) { _, newValue in
            updateWindowTitle(for: newValue)
        }
        .onAppear {
            updateWindowTitle(for: selectedMenuItem)
        }
    }

    // MARK: - Sidebar

    /// The sidebar containing the menu items.
    private var sidebarContent: some View {
        List {
            ForEach(MenuItem.allCases) { item in
                menuItemRow(for: item)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color.aBackground)
        .frame(minWidth: 150, idealWidth: 200, maxWidth: 250)
        .padding(.top, .spacingL)
    }

    /// Creates a row for the specified menu item.
    ///
    /// - Parameter item: The menu item to create a row for.
    /// - Returns: A view representing the menu item.
    private func menuItemRow(for item: MenuItem) -> some View {
        Button {
            if item == .rateApp {
                Task {
                    await AppStoreReviewManager.requestReviewManually()
                }
            } else {
                selectedMenuItem = item
            }
        } label: {
            Text(item.localizedName)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(selectedMenuItem == item ? Color.white : Color.primary)
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            selectedMenuItem == item
                                ? Color.accentColor
                                : Color.clear
                        )
                )
                .contentShape(RoundedRectangle(cornerRadius: 6))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
    }

    // MARK: - Detail Content

    /// The detail pane showing the selected category's settings.
    private var detailContent: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            detailView(for: selectedMenuItem)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.spacingL)
        .background(Color.aBackground)
    }

    /// Returns the appropriate detail view for the selected menu item.
    ///
    /// - Parameter item: The currently selected menu item.
    /// - Returns: A view displaying the settings for the selected category.
    @ViewBuilder
    private func detailView(for item: MenuItem) -> some View {
        switch item {
        case .settings:
            appSettingsView
        case .imprint:
            imprintView
        case .privacy:
            privacyView
        case .rateApp:
            EmptyView()
        #if DEBUG
        case .developer:
            developerView
        #endif
        }
    }

    /// Creates a placeholder detail view for unfinished preference sections.
    ///
    /// - Parameters:
    ///   - title: The section title.
    ///   - message: The placeholder message.
    /// - Returns: A standardized placeholder settings view.
    func placeholderSettingsView(
        title: String,
        message: String
    ) -> some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Text(title)
                .textStyle(.title3)
                .foregroundStyle(Color.aPrimary)

            Text(message)
                .foregroundStyle(Color.aPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Helper Views

    /// Creates a section header for preference sections.
    ///
    /// - Parameter title: The section title.
    /// - Returns: A styled section header view.
    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .textStyle(.title3)
            .foregroundStyle(Color.aPrimary)
    }

    /// Creates a settings row with an icon and title.
    ///
    /// - Parameters:
    ///   - title: The row title.
    ///   - icon: The SF Symbol name for the icon.
    ///   - iconColor: The color for the icon.
    /// - Returns: A styled settings row view.
    func settingsRow(
        title: String,
        icon: String,
        iconColor: Color
    ) -> some View {
        HStack(spacing: .spacingM) {
            Image(systemName: icon)
                .imageScale(.medium)
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)

            Text(title)
                .textStyle(.body1)
                .foregroundStyle(Color.aPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .imageScale(.small)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    // MARK: - Window Management

    /// Updates the window title based on the selected menu item.
    ///
    /// - Parameter item: The menu item to use for the window title.
    private func updateWindowTitle(for item: MenuItem) {
        // Get the current window from the view's hosting window
        if let window = NSApplication.shared.keyWindow {
            window.title = item.localizedName
        }
    }

    /// Resolves the locale used by the preferences window.
    private var preferencesLocale: Locale {
        if appLanguageOverrideCode == "system" {
            return .current
        }
        return Locale(identifier: appLanguageOverrideCode)
    }
}

// MARK: - NSWindow Extension

public extension NSWindow {
    /// Creates a standard preferences-style window.
    ///
    /// The window is configured with standard styling and is automatically centered on screen.
    ///
    /// - Parameters:
    ///   - title: The window title.
    ///   - width: The window width in points. Defaults to 800.
    ///   - height: The window height in points. Defaults to 600.
    /// - Returns: A configured NSWindow instance.
    static func createStandardWindow(
        withTitle title: String,
        width: CGFloat = 800,
        height: CGFloat = 600
    ) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = title
        return window
    }
}

#endif // os(macOS)
