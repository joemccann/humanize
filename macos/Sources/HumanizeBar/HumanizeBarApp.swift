import SwiftUI

@main
struct HumanizeBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(appDelegate.settingsStore)
        }
    }
}
