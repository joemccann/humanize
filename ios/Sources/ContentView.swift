import SwiftUI
import HumanizeShared

struct ContentView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        NavigationStack {
            HumanizeView()
        }
        .preferredColorScheme(settings.appearance.colorScheme)
    }
}
