import Testing
import Foundation
@testable import HumanizeBar

@MainActor
@Suite("SettingsStore")
struct SettingsStoreTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("Default values")
    func defaults() {
        let store = SettingsStore(defaults: freshDefaults())
        #expect(store.tone == .natural)
        #expect(store.provider == .openai)
        #expect(store.openaiAPIKey == "")
        #expect(store.anthropicAPIKey == "")
    }

    @Test("Values persist across instances")
    func persistence() {
        let defaults = freshDefaults()
        let store1 = SettingsStore(defaults: defaults)
        store1.tone = .professional
        store1.provider = .anthropic
        store1.openaiAPIKey = "sk-test"
        store1.anthropicAPIKey = "ant-test"

        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.tone == .professional)
        #expect(store2.provider == .anthropic)
        #expect(store2.openaiAPIKey == "sk-test")
        #expect(store2.anthropicAPIKey == "ant-test")
    }

    @Test("hasRequiredAPIKey is true when selected provider key is set")
    func hasRequiredKeyTrue() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .openai
        store.openaiAPIKey = "sk-key"
        #expect(store.hasRequiredAPIKey == true)
    }

    @Test("hasRequiredAPIKey is false when selected provider key is empty")
    func hasRequiredKeyFalse() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .openai
        store.openaiAPIKey = ""
        #expect(store.hasRequiredAPIKey == false)
    }

    @Test("hasRequiredAPIKey checks the correct provider")
    func hasRequiredKeyWrongProvider() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .openai
        store.anthropicAPIKey = "ant-key"
        store.openaiAPIKey = ""
        #expect(store.hasRequiredAPIKey == false)
    }

    @Test("currentAPIKey returns key for selected provider")
    func currentAPIKey() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .anthropic
        store.anthropicAPIKey = "ant-key"
        store.openaiAPIKey = "sk-key"
        #expect(store.currentAPIKey == "ant-key")

        store.provider = .openai
        #expect(store.currentAPIKey == "sk-key")
    }

    @Test("currentAPIKey returns nil when key is empty")
    func currentAPIKeyNil() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .openai
        store.openaiAPIKey = ""
        #expect(store.currentAPIKey == nil)
    }

    @Test("Appearance persists across instances")
    func appearancePersistence() {
        let defaults = freshDefaults()
        let store1 = SettingsStore(defaults: defaults)
        store1.appearance = .dark
        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.appearance == .dark)
    }

    @Test("Default appearance is system")
    func defaultAppearance() {
        let store = SettingsStore(defaults: freshDefaults())
        #expect(store.appearance == .system)
    }

    @Test("All tones round-trip through persistence", arguments: HumanizeTone.allCases)
    func tonePersistence(tone: HumanizeTone) {
        let defaults = freshDefaults()
        let store1 = SettingsStore(defaults: defaults)
        store1.tone = tone
        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.tone == tone)
    }

    @Test("All providers round-trip through persistence", arguments: AIProvider.allCases)
    func providerPersistence(provider: AIProvider) {
        let defaults = freshDefaults()
        let store1 = SettingsStore(defaults: defaults)
        store1.provider = provider
        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.provider == provider)
    }

    @Test("All appearances round-trip through persistence", arguments: AppAppearance.allCases)
    func allAppearancePersistence(appearance: AppAppearance) {
        let defaults = freshDefaults()
        let store1 = SettingsStore(defaults: defaults)
        store1.appearance = appearance
        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.appearance == appearance)
    }

    @Test("Corrupted tone in defaults falls back to .natural")
    func corruptedTone() {
        let defaults = freshDefaults()
        defaults.set("invalid_tone", forKey: "humanize.tone")
        let store = SettingsStore(defaults: defaults)
        #expect(store.tone == .natural)
    }

    @Test("Corrupted provider in defaults falls back to .openai")
    func corruptedProvider() {
        let defaults = freshDefaults()
        defaults.set("invalid_provider", forKey: "humanize.provider")
        let store = SettingsStore(defaults: defaults)
        #expect(store.provider == .openai)
    }

    @Test("Corrupted appearance in defaults falls back to .system")
    func corruptedAppearance() {
        let defaults = freshDefaults()
        defaults.set("invalid_appearance", forKey: "humanize.appearance")
        let store = SettingsStore(defaults: defaults)
        #expect(store.appearance == .system)
    }

    @Test("Setting API key immediately updates hasRequiredAPIKey")
    func immediateKeyUpdate() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .openai
        #expect(store.hasRequiredAPIKey == false)
        store.openaiAPIKey = "sk-new"
        #expect(store.hasRequiredAPIKey == true)
        store.openaiAPIKey = ""
        #expect(store.hasRequiredAPIKey == false)
    }

    @Test("Both keys set — currentAPIKey returns the active provider's key")
    func bothKeysSet() {
        let store = SettingsStore(defaults: freshDefaults())
        store.openaiAPIKey = "sk-open"
        store.anthropicAPIKey = "ant-key"

        store.provider = .openai
        #expect(store.currentAPIKey == "sk-open")

        store.provider = .anthropic
        #expect(store.currentAPIKey == "ant-key")
    }
}
