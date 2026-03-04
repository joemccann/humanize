#if os(macOS)
import AppKit

/// A borderless, Spotlight-style floating panel that can receive keyboard input.
///
/// Subclasses `NSPanel` and overrides `canBecomeKey` / `canBecomeMain` so the
/// panel immediately accepts typing when summoned via the global hotkey.
final class FloatingPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 56),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .statusBar
        isOpaque = false
        backgroundColor = .clear
        hidesOnDeactivate = true
        isMovableByWindowBackground = false
        hasShadow = true

        // Center on the main screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - frame.width / 2
            let y = screenFrame.midY - frame.height / 2 + screenFrame.height * 0.2
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
#endif
