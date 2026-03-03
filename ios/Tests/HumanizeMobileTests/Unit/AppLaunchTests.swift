import Testing
import SwiftUI
@testable import HumanizeMobile
import HumanizeShared

@MainActor
@Suite("App Launch")
struct AppLaunchTests {
    @Test("HumanizeMobileApp can be instantiated")
    func appInstantiation() {
        let app = HumanizeMobileApp()
        _ = app
    }

    @Test("ContentView can be instantiated with settings environment")
    func contentViewCreation() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let view = ContentView().environment(store)
        _ = view
    }
}
