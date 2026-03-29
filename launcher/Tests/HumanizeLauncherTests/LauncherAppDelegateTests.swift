#if os(macOS)
import Testing
import AppKit
@testable import HumanizeLauncher
import HumanizeShared

@MainActor
@Suite("LauncherAppDelegate")
struct LauncherAppDelegateTests {
    @Test("LauncherAppDelegate can be instantiated")
    func creation() {
        let delegate = LauncherAppDelegate()
        #expect(delegate.settingsStore.tone == .natural)
    }

    @Test("LauncherAppDelegate has default settings")
    func defaultSettings() {
        let delegate = LauncherAppDelegate()
        #expect(delegate.settingsStore.provider == .cerebras)
        #expect(delegate.settingsStore.appearance == .system)
    }

    @Test("LauncherAppDelegate has a panel manager")
    func hasPanelManager() {
        let delegate = LauncherAppDelegate()
        #expect(delegate.panelManager.isPanelVisible == false)
    }

    @Test("LauncherAppDelegate panel manager starts hidden")
    func panelStartsHidden() {
        let delegate = LauncherAppDelegate()
        #expect(delegate.panelManager.isPanelVisible == false)
    }
}
#endif
