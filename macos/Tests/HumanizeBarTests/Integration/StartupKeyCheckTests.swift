import Testing
import Foundation
@testable import HumanizeBar

@MainActor
@Suite("Startup Key Check")
struct StartupKeyCheckTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("No API key set → hasRequiredAPIKey is false")
    func noKeySet() {
        let store = SettingsStore(defaults: freshDefaults())
        #expect(store.hasRequiredAPIKey == false)
    }

    @Test("OpenAI key set, provider = openai → hasRequiredAPIKey is true")
    func openaiKeyWithOpenaiProvider() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .openai
        store.openaiAPIKey = "sk-valid"
        #expect(store.hasRequiredAPIKey == true)
    }

    @Test("Anthropic key set, provider = openai → hasRequiredAPIKey is false")
    func anthropicKeyWithOpenaiProvider() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .openai
        store.anthropicAPIKey = "ant-valid"
        store.openaiAPIKey = ""
        #expect(store.hasRequiredAPIKey == false)
    }

    @Test("Anthropic key set, provider = anthropic → hasRequiredAPIKey is true")
    func anthropicKeyWithAnthropicProvider() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .anthropic
        store.anthropicAPIKey = "ant-valid"
        #expect(store.hasRequiredAPIKey == true)
    }

    @Test("Switching provider updates hasRequiredAPIKey")
    func switchingProvider() {
        let store = SettingsStore(defaults: freshDefaults())
        store.openaiAPIKey = "sk-valid"
        store.anthropicAPIKey = ""

        store.provider = .openai
        #expect(store.hasRequiredAPIKey == true)

        store.provider = .anthropic
        #expect(store.hasRequiredAPIKey == false)

        store.anthropicAPIKey = "ant-valid"
        #expect(store.hasRequiredAPIKey == true)
    }
}
