import SwiftUI
import HumanizeShared

@main
struct HumanizeMobileApp: App {
    @State private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)
        }
    }
}
