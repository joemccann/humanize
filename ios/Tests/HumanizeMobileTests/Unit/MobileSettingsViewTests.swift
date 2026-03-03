import Testing
import SwiftUI
@testable import HumanizeMobile
import HumanizeShared

@MainActor
@Suite("MobileSettingsView")
struct MobileSettingsViewTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("MobileSettingsView can be instantiated")
    func viewCreation() {
        let store = SettingsStore(defaults: freshDefaults())
        let view = MobileSettingsView().environment(store)
        _ = view
    }

    @Test("MobileSettingsView instantiates per provider", arguments: AIProvider.allCases)
    func perProvider(provider: AIProvider) {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = provider
        let view = MobileSettingsView().environment(store)
        _ = view
    }

    @Test("MobileSettingsView instantiates per appearance", arguments: AppAppearance.allCases)
    func perAppearance(appearance: AppAppearance) {
        let store = SettingsStore(defaults: freshDefaults())
        store.appearance = appearance
        let view = MobileSettingsView().environment(store)
        _ = view
    }
}
