#if os(macOS)
import Testing
import SwiftUI
import AppKit
@testable import HumanizeLauncher
import HumanizeShared

@MainActor
@Suite("LauncherInputView")
struct LauncherInputViewTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("LauncherInputView can be instantiated")
    func creation() {
        let store = SettingsStore(defaults: freshDefaults())
        let view = LauncherInputView(
            onSubmit: { _ in },
            onDismiss: {}
        ).environment(store)
        _ = view
    }

    @Test("LauncherInputView renders in hosting controller")
    func hostingController() {
        let store = SettingsStore(defaults: freshDefaults())
        let controller = NSHostingController(
            rootView: LauncherInputView(
                onSubmit: { _ in },
                onDismiss: {}
            ).environment(store)
        )
        #expect(controller.view.frame.width >= 0)
    }
}
#endif
