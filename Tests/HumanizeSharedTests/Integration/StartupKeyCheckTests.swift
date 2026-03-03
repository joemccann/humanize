import Testing
import Foundation
@testable import HumanizeShared

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

    @Test("Cerebras key set, provider = cerebras - hasRequiredAPIKey is true")
    func cerebrasKeyWithCerebrasProvider() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .cerebras
        store.cerebrasAPIKey = "cbr-valid"
        #expect(store.hasRequiredAPIKey == true)
    }

    @Test("Anthropic key set, provider = cerebras - hasRequiredAPIKey is true via backup")
    func anthropicKeyWithCerebrasProvider() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .cerebras
        store.anthropicAPIKey = "ant-valid"
        store.cerebrasAPIKey = ""
        #expect(store.hasRequiredAPIKey == true)
        #expect(store.currentProviderForRequest == .anthropic)
    }

    @Test("Anthropic key set, provider = anthropic - hasRequiredAPIKey is true")
    func anthropicKeyWithAnthropicProvider() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .anthropic
        store.anthropicAPIKey = "ant-valid"
        #expect(store.hasRequiredAPIKey == true)
    }

    @Test("Switching to provider without key auto-normalizes to a keyed provider")
    func switchingProvider() {
        let store = SettingsStore(defaults: freshDefaults())
        store.cerebrasAPIKey = "cbr-valid"
        store.openaiAPIKey = "sk-valid"
        store.anthropicAPIKey = ""

        store.provider = .cerebras
        #expect(store.hasRequiredAPIKey == true)

        store.provider = .openai
        #expect(store.hasRequiredAPIKey == true)

        store.provider = .anthropic
        #expect(store.hasRequiredAPIKey == true)
        #expect(store.currentProviderForRequest == .cerebras)
        #expect(store.provider == .cerebras)

        store.anthropicAPIKey = "ant-valid"
        #expect(store.hasRequiredAPIKey == true)
        #expect(store.currentProviderForRequest == .cerebras)
    }
}
