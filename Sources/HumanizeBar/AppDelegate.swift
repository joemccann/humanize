import AppKit
import SwiftUI
import HumanizeShared

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var rightClickMenu: NSMenu?
    private var resizeStartSize: NSSize?
    let settingsStore = SettingsStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let popover = NSPopover()
        popover.contentSize = PopoverSizing.defaultSize
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(onResize: { [weak self] delta, ended in
                self?.resizePopover(by: delta, ended: ended)
            })
                .environment(settingsStore)
        )
        self.popover = popover

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "text.bubble",
                accessibilityDescription: "Humanize"
            )
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        self.statusItem = statusItem

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Humanize", action: #selector(quit), keyEquivalent: "q"))
        self.rightClickMenu = menu

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.popover?.performClose(nil)
        }

        // Auto-show popover on launch when no API key is configured
        if !settingsStore.hasRequiredAPIKey {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self, let button = self.statusItem?.button else { return }
                self.popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            popover?.performClose(nil)
            statusItem?.menu = rightClickMenu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            guard let popover, let button = statusItem?.button else { return }
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func resizePopover(by translation: CGSize, ended: Bool) {
        guard let popover else { return }

        if resizeStartSize == nil {
            resizeStartSize = popover.contentSize
        }

        guard let startSize = resizeStartSize else { return }

        let width = clamp(
            startSize.width + translation.width,
            min: PopoverSizing.minSize.width,
            max: PopoverSizing.maxSize.width
        )
        let height = clamp(
            startSize.height + translation.height,
            min: PopoverSizing.minSize.height,
            max: PopoverSizing.maxSize.height
        )

        popover.contentSize = NSSize(width: width, height: height)

        if ended {
            resizeStartSize = nil
        }
    }

    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.max(min, Swift.min(max, value))
    }
}
