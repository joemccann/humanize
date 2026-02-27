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
}
