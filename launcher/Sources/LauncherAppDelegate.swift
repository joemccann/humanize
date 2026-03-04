#if os(macOS)
import AppKit
import SwiftUI
import HumanizeShared

/// App delegate for the launcher variant of Humanize.
///
/// Runs as a background-only app (`LSUIElement = YES`). Creates a menu-bar
/// status item and manages the `PanelManager` that owns the floating panel.
@MainActor
final class LauncherAppDelegate: NSObject, NSApplicationDelegate {
    let settingsStore = SettingsStore()
    private(set) lazy var panelManager = PanelManager(settingsStore: settingsStore)

    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Force lazy initialization of panelManager
        _ = panelManager

        // Menu bar icon
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "text.bubble",
                accessibilityDescription: "Humanize Launcher"
            )
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        self.statusItem = statusItem
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "Quit Humanize", action: #selector(quit), keyEquivalent: "q"))
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            panelManager.togglePanel()
        }
    }

    @objc private func openSettings() {
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = "Humanize Settings"
        settingsWindow.center()
        settingsWindow.contentView = NSHostingView(
            rootView: LauncherSettingsView().environment(settingsStore)
        )
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
#endif
