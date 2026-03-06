#if os(macOS)
import Testing
import SwiftUI
import AppKit
@testable import HumanizeLauncher
import HumanizeShared

@MainActor
@Suite("LauncherSettingsView")
struct LauncherSettingsViewTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("LauncherSettingsView can be instantiated with settings environment")
    func creation() {
        let store = SettingsStore(defaults: freshDefaults())
        let view = LauncherSettingsView().environment(store)
        _ = view
    }

    @Test("LauncherSettingsView renders in NSHostingController without crash")
    func hostingController() {
        let store = SettingsStore(defaults: freshDefaults())
        let controller = NSHostingController(
            rootView: LauncherSettingsView().environment(store)
        )
        let view = controller.view
        #expect(view.frame.width >= 0)
    }

    @Test("LauncherSettingsView instantiates across providers", arguments: AIProvider.allCases)
    func perProvider(provider: AIProvider) {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = provider
        let controller = NSHostingController(
            rootView: LauncherSettingsView().environment(store)
        )
        #expect(controller.view.frame.width >= 0)
    }
}
#endif
