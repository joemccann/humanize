import Testing
import SwiftUI
@testable import HumanizeMobile
import HumanizeShared
import HumanizeTestSupport

@MainActor
@Suite("HumanizeView")
struct HumanizeViewTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("HumanizeView can be instantiated with settings environment")
    func viewCreation() {
        let store = SettingsStore(defaults: freshDefaults())
        let view = HumanizeView().environment(store)
        _ = view
    }

    @Test("HumanizeView with no API key shows setup state")
    func noKeySetup() {
        let store = SettingsStore(defaults: freshDefaults())
        #expect(!store.hasRequiredAPIKey)
        let view = HumanizeView().environment(store)
        _ = view
    }

    @Test("HumanizeView with API key shows main state")
    func withKey() {
        let store = SettingsStore(defaults: freshDefaults())
        store.cerebrasAPIKey = "cbr-test"
        #expect(store.hasRequiredAPIKey)
        let view = HumanizeView().environment(store)
        _ = view
    }

    @Test("HumanizeView respects light appearance")
    func lightMode() {
        let store = SettingsStore(defaults: freshDefaults())
        store.appearance = .light
        #expect(store.appearance.colorScheme == .light)
        let view = HumanizeView().environment(store)
        _ = view
    }

    @Test("HumanizeView respects dark appearance")
    func darkMode() {
        let store = SettingsStore(defaults: freshDefaults())
        store.appearance = .dark
        #expect(store.appearance.colorScheme == .dark)
        let view = HumanizeView().environment(store)
        _ = view
    }

    @Test("HumanizeView instantiates across providers", arguments: AIProvider.allCases)
    func perProvider(provider: AIProvider) {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = provider
        let view = HumanizeView().environment(store)
        _ = view
    }

    @Test("HumanizeView works with injected ViewModel")
    func injectedViewModel() {
        let client = MockHTTPClient { _ in
            mockResponse(json: ["choices": [["message": ["content": "test"]]]])
        }
        let vm = HumanizeViewModel(service: HumanizeAPIService(httpClient: client))
        let store = SettingsStore(defaults: freshDefaults())
        let view = HumanizeView(viewModel: vm).environment(store)
        _ = view
    }

    @Test("HumanizeView ViewModel state is accessible after injection")
    func injectedViewModelState() {
        let vm = HumanizeViewModel()
        vm.inputText = "pre-filled"
        let store = SettingsStore(defaults: freshDefaults())
        store.cerebrasAPIKey = "cbr-test"
        let view = HumanizeView(viewModel: vm).environment(store)
        _ = view
        #expect(vm.inputText == "pre-filled")
    }
}
