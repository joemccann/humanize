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
        #expect(store.provider == .cerebras)
        #expect(store.cerebrasAPIKey == "")
        #expect(store.openaiAPIKey == "")
        #expect(store.anthropicAPIKey == "")
    }

    @Test("Values persist across instances")
    func persistence() {
        let defaults = freshDefaults()
        let store1 = SettingsStore(defaults: defaults)
        store1.tone = .professional
        store1.cerebrasAPIKey = "cbr-test"
        store1.openaiAPIKey = "sk-test"
        store1.anthropicAPIKey = "ant-test"
        store1.provider = .anthropic

        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.tone == .professional)
        #expect(store2.provider == .anthropic)
        #expect(store2.cerebrasAPIKey == "cbr-test")
        #expect(store2.openaiAPIKey == "sk-test")
        #expect(store2.anthropicAPIKey == "ant-test")
    }

    @Test("hasRequiredAPIKey is true when selected provider key is set")
    func hasRequiredKeyTrue() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .cerebras
        store.cerebrasAPIKey = "cbr-key"
        #expect(store.hasRequiredAPIKey == true)
    }

    @Test("hasRequiredAPIKey is false when no provider keys are set")
    func hasRequiredKeyFalse() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .cerebras
        store.cerebrasAPIKey = ""
        store.openaiAPIKey = ""
        store.anthropicAPIKey = ""
        #expect(store.hasRequiredAPIKey == false)
    }

    @Test("hasRequiredAPIKey is true when backup provider key is set")
    func hasRequiredKeyFromBackupProvider() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .cerebras
        store.cerebrasAPIKey = ""
        store.anthropicAPIKey = "ant-key"
        #expect(store.provider == .anthropic)
        #expect(store.hasRequiredAPIKey == true)
        #expect(store.currentProviderForRequest == .anthropic)
    }

    @Test("currentAPIKey returns selected provider key when present")
    func currentAPIKey() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .anthropic
        store.anthropicAPIKey = "ant-key"
        store.cerebrasAPIKey = "cbr-key"
        store.openaiAPIKey = "sk-key"
        #expect(store.currentAPIKey == "ant-key")
        #expect(store.currentProviderForRequest == .anthropic)

        store.provider = .cerebras
        #expect(store.currentAPIKey == "cbr-key")
        #expect(store.currentProviderForRequest == .cerebras)
    }

    @Test("currentAPIKey falls back to next configured provider")
    func currentAPIKeyFallback() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .cerebras
        store.cerebrasAPIKey = ""
        store.openaiAPIKey = "sk-key"
        store.anthropicAPIKey = "ant-key"

        #expect(store.currentProviderForRequest == .openai)
        #expect(store.currentAPIKey == "sk-key")

        store.openaiAPIKey = ""
        #expect(store.currentProviderForRequest == .anthropic)
        #expect(store.currentAPIKey == "ant-key")
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

    @Test("Corrupted provider in defaults falls back to .cerebras")
    func corruptedProvider() {
        let defaults = freshDefaults()
        defaults.set("invalid_provider", forKey: "humanize.provider")
        let store = SettingsStore(defaults: defaults)
        #expect(store.provider == .cerebras)
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
        store.provider = .cerebras
        #expect(store.hasRequiredAPIKey == false)
        store.cerebrasAPIKey = "cbr-new"
        #expect(store.hasRequiredAPIKey == true)
        store.cerebrasAPIKey = ""
        #expect(store.hasRequiredAPIKey == false)
    }

    @Test("All keys set - currentAPIKey returns the active provider's key")
    func bothKeysSet() {
        let store = SettingsStore(defaults: freshDefaults())
        store.cerebrasAPIKey = "cbr-key"
        store.openaiAPIKey = "sk-open"
        store.anthropicAPIKey = "ant-key"

        store.provider = .cerebras
        #expect(store.currentAPIKey == "cbr-key")

        store.provider = .openai
        #expect(store.currentAPIKey == "sk-open")

        store.provider = .anthropic
        #expect(store.currentAPIKey == "ant-key")
    }

    @Test("providerAttemptOrder starts with selected provider")
    func providerAttemptOrder() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .openai
        #expect(store.providerAttemptOrder == [.openai])
    }

    @Test("providerAttemptOrder — Cerebras falls back cross-provider, others stay strict")
    func providerAttemptOrderByProvider() {
        let store = SettingsStore(defaults: freshDefaults())
        store.cerebrasAPIKey = "cbr-key"
        store.openaiAPIKey = "sk-key"
        store.anthropicAPIKey = "ant-key"

        store.provider = .cerebras
        #expect(store.providerAttemptOrder == [.cerebras, .openai, .anthropic])

        store.provider = .openai
        #expect(store.providerAttemptOrder == [.openai])

        store.provider = .anthropic
        #expect(store.providerAttemptOrder == [.anthropic])
    }

    @Test("selectableProviders follows recommended order of configured keys")
    func selectableProvidersOrder() {
        let store = SettingsStore(defaults: freshDefaults())
        store.cerebrasAPIKey = ""
        store.openaiAPIKey = "sk-key"
        store.anthropicAPIKey = "ant-key"

        #expect(store.selectableProviders == [.openai, .anthropic])

        store.cerebrasAPIKey = "cbr-key"
        #expect(store.selectableProviders == [.cerebras, .openai, .anthropic])
    }

    @Test("Provider cannot remain selected without API key when another provider has a key")
    func providerSelectionRequiresKey() {
        let store = SettingsStore(defaults: freshDefaults())
        store.openaiAPIKey = "sk-key"
        store.cerebrasAPIKey = ""
        store.anthropicAPIKey = ""
        store.provider = .cerebras

        #expect(store.provider == .openai)
        #expect(store.hasAPIKey(for: store.provider))
    }

    @Test("apiKey(for:) returns nil for empty and value for configured providers")
    func apiKeyForProvider() {
        let store = SettingsStore(defaults: freshDefaults())
        store.cerebrasAPIKey = ""
        store.openaiAPIKey = "sk-key"
        store.anthropicAPIKey = ""

        #expect(store.apiKey(for: .cerebras) == nil)
        #expect(store.apiKey(for: .openai) == "sk-key")
        #expect(store.apiKey(for: .anthropic) == nil)
    }

    @Test("Whitespace-only API keys are treated as missing")
    func whitespaceOnlyKeys() {
        let store = SettingsStore(defaults: freshDefaults())
        store.cerebrasAPIKey = "   "
        store.openaiAPIKey = "\n\t"
        store.anthropicAPIKey = "  \n  "

        #expect(store.apiKey(for: .cerebras) == nil)
        #expect(store.apiKey(for: .openai) == nil)
        #expect(store.apiKey(for: .anthropic) == nil)
        #expect(store.selectableProviders.isEmpty)
        #expect(store.hasRequiredAPIKey == false)
    }

    @Test("API keys are trimmed before use")
    func trimmedKeys() {
        let store = SettingsStore(defaults: freshDefaults())
        store.openaiAPIKey = "  sk-key  \n"

        #expect(store.apiKey(for: .openai) == "sk-key")
        #expect(store.currentProviderForRequest == .openai)
    }
}
