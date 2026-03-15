#if os(macOS)
import AppKit
import SwiftUI
import KeyboardShortcuts
import HumanizeShared

/// Owns the `FloatingPanel` and listens for the global hotkey to toggle it.
@MainActor
final class PanelManager {
    let panel: FloatingPanel
    private let settingsStore: SettingsStore

    var isPanelVisible: Bool {
        panel.isVisible
    }

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.panel = FloatingPanel()

        setupPanelContent()
        registerHotkey()
    }

    // MARK: - Panel visibility

    func togglePanel() {
        if isPanelVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    func showPanel() {
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hidePanel() {
        panel.orderOut(nil)
    }

    // MARK: - Private

    private func setupPanelContent() {
        let service = HumanizeAPIService()

        let contentView = LauncherInputView(
            onSubmit: { [weak self] text in
                guard let self else { return }
                await self.processText(text, service: service)
            },
            onDismiss: { [weak self] in
                self?.hidePanel()
            }
        )
        .environment(settingsStore)

        let hostingView = NSHostingView(rootView: contentView)
        panel.contentView = hostingView
    }

    private func registerHotkey() {
        KeyboardShortcuts.onKeyUp(for: .togglePanel) { [weak self] in
            Task { @MainActor in
                self?.togglePanel()
            }
        }
    }

    private func processText(_ text: String, service: HumanizeAPIService) async {
        let input = normalizeInputWhitespace(text)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        let attemptOrder = settingsStore.providerAttemptOrder

        for provider in attemptOrder {
            if Task.isCancelled { break }
            guard let apiKey = settingsStore.apiKey(for: provider) else { continue }

            do {
                let result = try await service.humanize(
                    text: input,
                    tone: settingsStore.tone,
                    provider: provider,
                    apiKey: apiKey
                )

                guard !Task.isCancelled else { return }

                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(result.text, forType: .string)

                hidePanel()
                return
            } catch {
                continue
            }
        }
    }
}
#endif
