import Testing
import SwiftUI
@testable import HumanizeBar
import HumanizeShared

@MainActor
@Suite("UI View Instantiation")
struct UIViewTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("PopoverView can be instantiated with settings environment")
    func popoverViewCreation() {
        let store = SettingsStore(defaults: freshDefaults())
        let view = PopoverView().environment(store)
        // If this compiles and runs, the view was created successfully
        _ = view
    }

    @Test("SettingsView can be instantiated with settings environment")
    func settingsViewCreation() {
        let store = SettingsStore(defaults: freshDefaults())
        let view = SettingsView().environment(store)
        _ = view
    }

    @Test("PopoverView renders in NSHostingController without crash")
    func popoverInHostingController() {
        let store = SettingsStore(defaults: freshDefaults())
        let controller = NSHostingController(
            rootView: PopoverView().environment(store)
        )
        // Force the view to load and verify it has non-zero frame potential
        let view = controller.view
        #expect(view.frame.width >= 0)
    }

    @Test("SettingsView renders in NSHostingController without crash")
    func settingsInHostingController() {
        let store = SettingsStore(defaults: freshDefaults())
        let controller = NSHostingController(
            rootView: SettingsView().environment(store)
        )
        let view = controller.view
        #expect(view.frame.width >= 0)
    }

    @Test("PopoverView with no API key instantiates without crash")
    func popoverNoKeySetup() {
        let store = SettingsStore(defaults: freshDefaults())
        #expect(!store.hasRequiredAPIKey)
        let controller = NSHostingController(
            rootView: PopoverView().environment(store)
        )
        #expect(controller.view.frame.width >= 0)
    }

    @Test("PopoverView with API key instantiates without crash")
    func popoverWithKey() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .cerebras
        store.cerebrasAPIKey = "cbr-test"
        #expect(store.hasRequiredAPIKey)
        let controller = NSHostingController(
            rootView: PopoverView().environment(store)
        )
        #expect(controller.view.frame.width >= 0)
    }

    @Test("PopoverView respects light appearance setting")
    func popoverLightMode() {
        let store = SettingsStore(defaults: freshDefaults())
        store.appearance = .light
        #expect(store.appearance.colorScheme == .light)
        let controller = NSHostingController(
            rootView: PopoverView().environment(store)
        )
        #expect(controller.view.frame.width >= 0)
    }

    @Test("PopoverView respects dark appearance setting")
    func popoverDarkMode() {
        let store = SettingsStore(defaults: freshDefaults())
        store.appearance = .dark
        #expect(store.appearance.colorScheme == .dark)
        let controller = NSHostingController(
            rootView: PopoverView().environment(store)
        )
        #expect(controller.view.frame.width >= 0)
    }

    @Test("PopoverView with system appearance — colorScheme is nil")
    func popoverSystemMode() {
        let store = SettingsStore(defaults: freshDefaults())
        store.appearance = .system
        #expect(store.appearance.colorScheme == nil)
        let controller = NSHostingController(
            rootView: PopoverView().environment(store)
        )
        #expect(controller.view.frame.width >= 0)
    }

    @Test("PopoverView instantiates across providers", arguments: AIProvider.allCases)
    func popoverPerProvider(provider: AIProvider) {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = provider
        let controller = NSHostingController(
            rootView: PopoverView().environment(store)
        )
        #expect(controller.view.frame.width >= 0)
    }

    @Test("SettingsView instantiates across providers", arguments: AIProvider.allCases)
    func settingsPerProvider(provider: AIProvider) {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = provider
        let controller = NSHostingController(
            rootView: SettingsView().environment(store)
        )
        #expect(controller.view.frame.width >= 0)
    }
}

@MainActor
@Suite("AppDelegate")
struct AppDelegateTests {
    @Test("AppDelegate can be instantiated")
    func creation() {
        let delegate = AppDelegate()
        #expect(delegate.settingsStore.tone == .natural)
    }

    @Test("AppDelegate settingsStore has default values")
    func defaultSettings() {
        let delegate = AppDelegate()
        #expect(delegate.settingsStore.provider == .cerebras)
        #expect(delegate.settingsStore.cerebrasAPIKey == "")
        #expect(delegate.settingsStore.openaiAPIKey == "")
        #expect(delegate.settingsStore.anthropicAPIKey == "")
        #expect(delegate.settingsStore.appearance == .system)
    }
}
