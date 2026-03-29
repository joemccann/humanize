#if os(macOS)
import Testing
import AppKit
@testable import HumanizeLauncher
import HumanizeShared

@MainActor
@Suite("PanelManager")
struct PanelManagerTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("PanelManager can be instantiated")
    func creation() {
        let store = SettingsStore(defaults: freshDefaults())
        let manager = PanelManager(settingsStore: store)
        #expect(manager.isPanelVisible == false)
    }

    @Test("togglePanel shows the panel when hidden")
    func toggleShowsPanel() {
        let store = SettingsStore(defaults: freshDefaults())
        let manager = PanelManager(settingsStore: store)
        manager.togglePanel()
        #expect(manager.isPanelVisible == true)
    }

    @Test("togglePanel hides the panel when visible")
    func toggleHidesPanel() {
        let store = SettingsStore(defaults: freshDefaults())
        let manager = PanelManager(settingsStore: store)
        manager.togglePanel()
        #expect(manager.isPanelVisible == true)
        manager.togglePanel()
        #expect(manager.isPanelVisible == false)
    }

    @Test("showPanel makes panel visible")
    func showPanel() {
        let store = SettingsStore(defaults: freshDefaults())
        let manager = PanelManager(settingsStore: store)
        manager.showPanel()
        #expect(manager.isPanelVisible == true)
    }

    @Test("hidePanel makes panel hidden")
    func hidePanel() {
        let store = SettingsStore(defaults: freshDefaults())
        let manager = PanelManager(settingsStore: store)
        manager.showPanel()
        manager.hidePanel()
        #expect(manager.isPanelVisible == false)
    }

    @Test("PanelManager configures panel content")
    func panelContent() {
        let store = SettingsStore(defaults: freshDefaults())
        let manager = PanelManager(settingsStore: store)
        #expect(manager.panel.contentView != nil)
    }
}
#endif
