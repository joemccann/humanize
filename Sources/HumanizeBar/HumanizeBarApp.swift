import SwiftUI

@main
struct HumanizeBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible windows — everything lives in the menu bar popover
        Settings {
            EmptyView()
        }
    }
}
