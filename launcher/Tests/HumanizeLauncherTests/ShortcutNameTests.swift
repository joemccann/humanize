#if os(macOS)
import Testing
import KeyboardShortcuts
@testable import HumanizeLauncher

@MainActor
@Suite("KeyboardShortcuts.Name Extension")
struct ShortcutNameTests {
    @Test("togglePanel shortcut name is registered with correct identifier")
    func togglePanelIdentifier() {
        let name = KeyboardShortcuts.Name.togglePanel
        #expect(name.rawValue == "toggleHumanizePanel")
    }
}
#endif
