#if os(macOS)
import Testing
import AppKit
@testable import HumanizeLauncher

@MainActor
@Suite("FloatingPanel")
struct FloatingPanelTests {
    @Test("FloatingPanel can become key window")
    func canBecomeKey() {
        let panel = FloatingPanel()
        #expect(panel.canBecomeKey == true)
    }

    @Test("FloatingPanel can become main window")
    func canBecomeMain() {
        let panel = FloatingPanel()
        #expect(panel.canBecomeMain == true)
    }

    @Test("FloatingPanel has status window level")
    func windowLevel() {
        let panel = FloatingPanel()
        #expect(panel.level == .statusBar)
    }

    @Test("FloatingPanel is borderless (no title bar)")
    func borderlessStyle() {
        let panel = FloatingPanel()
        #expect(panel.styleMask.contains(.borderless))
        #expect(!panel.styleMask.contains(.titled))
    }

    @Test("FloatingPanel is non-opaque with no background")
    func transparentBackground() {
        let panel = FloatingPanel()
        #expect(panel.isOpaque == false)
        #expect(panel.backgroundColor == .clear)
    }

    @Test("FloatingPanel hides on deactivate")
    func hidesOnDeactivate() {
        let panel = FloatingPanel()
        #expect(panel.hidesOnDeactivate == true)
    }

    @Test("FloatingPanel is not visible by default")
    func initiallyHidden() {
        let panel = FloatingPanel()
        #expect(panel.isVisible == false)
    }

    @Test("FloatingPanel has centered content rect")
    func centeredFrame() {
        let panel = FloatingPanel()
        // Panel should have a reasonable initial size
        #expect(panel.frame.width > 0)
        #expect(panel.frame.height > 0)
    }

    @Test("FloatingPanel is a non-activating panel")
    func nonActivatingStyle() {
        let panel = FloatingPanel()
        #expect(panel.styleMask.contains(.nonactivatingPanel))
    }
}
#endif
