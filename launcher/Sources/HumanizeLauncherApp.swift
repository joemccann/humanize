#if os(macOS)
import SwiftUI
import HumanizeShared

@main
struct HumanizeLauncherApp: App {
    @NSApplicationDelegateAdaptor(LauncherAppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible windows — the app runs entirely via the floating panel
        // and menu-bar status item. Settings are opened from the right-click menu.
        Settings {
            EmptyView()
        }
    }
}
#endif
