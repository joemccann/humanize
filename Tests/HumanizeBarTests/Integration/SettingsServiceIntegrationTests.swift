import Testing
import Foundation
@testable import HumanizeBar

@MainActor
@Suite("Settings + Service Integration")
struct SettingsServiceIntegrationTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("OpenAI flow: configure settings → build request → mock call → parse response")
    func openaiEndToEnd() async throws {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .openai
        store.openaiAPIKey = "sk-integration"
        store.tone = .professional

        #expect(store.hasRequiredAPIKey)
        let apiKey = store.currentAPIKey!

        let client = MockHTTPClient { request in
            // Verify request was built with the correct provider endpoint
            #expect(request.url?.host == "api.openai.com")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-integration")

            return mockResponse(json: [
                "choices": [["message": ["content": "Professional rewrite"]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "AI text to rewrite",
            tone: store.tone,
            provider: store.provider,
            apiKey: apiKey
        )

        #expect(result.text == "Professional rewrite")
        #expect(result.provider == .openai)
    }

    @Test("Anthropic flow: configure settings → build request → mock call → parse response")
    func anthropicEndToEnd() async throws {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .anthropic
        store.anthropicAPIKey = "ant-integration"
        store.tone = .casual

        #expect(store.hasRequiredAPIKey)
        let apiKey = store.currentAPIKey!

        let client = MockHTTPClient { request in
            #expect(request.url?.host == "api.anthropic.com")
            #expect(request.value(forHTTPHeaderField: "x-api-key") == "ant-integration")

            return mockResponse(json: [
                "content": [["type": "text", "text": "Casual rewrite"]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "Formal text to make casual",
            tone: store.tone,
            provider: store.provider,
            apiKey: apiKey
        )

        #expect(result.text == "Casual rewrite")
        #expect(result.provider == .anthropic)
    }

    @Test("Switch provider mid-session: OpenAI → Anthropic → new call uses correct endpoint")
    func providerSwitch() async throws {
        let store = SettingsStore(defaults: freshDefaults())
        store.openaiAPIKey = "sk-key"
        store.anthropicAPIKey = "ant-key"
        store.provider = .openai

        // Start with OpenAI
        #expect(store.currentAPIKey == "sk-key")

        // Switch to Anthropic
        store.provider = .anthropic
        #expect(store.currentAPIKey == "ant-key")

        let client = MockHTTPClient { request in
            #expect(request.url?.host == "api.anthropic.com")
            return mockResponse(json: [
                "content": [["type": "text", "text": "Anthropic result"]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "test",
            tone: store.tone,
            provider: store.provider,
            apiKey: store.currentAPIKey!
        )

        #expect(result.provider == .anthropic)
        #expect(result.text == "Anthropic result")
    }

    @Test("Settings persist → new store → service call uses persisted provider")
    func persistenceAndService() async throws {
        let defaults = freshDefaults()

        // Session 1: configure
        let store1 = SettingsStore(defaults: defaults)
        store1.provider = .anthropic
        store1.anthropicAPIKey = "ant-persisted"
        store1.tone = .natural

        // Session 2: restore and use
        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.provider == .anthropic)
        #expect(store2.anthropicAPIKey == "ant-persisted")
        #expect(store2.hasRequiredAPIKey)

        let client = MockHTTPClient { request in
            #expect(request.url?.host == "api.anthropic.com")
            return mockResponse(json: [
                "content": [["type": "text", "text": "Persisted result"]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "test input",
            tone: store2.tone,
            provider: store2.provider,
            apiKey: store2.currentAPIKey!
        )

        #expect(result.text == "Persisted result")
    }

    @Test("Missing API key prevents humanize call")
    func missingKeyGuard() {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .openai
        store.openaiAPIKey = ""

        #expect(!store.hasRequiredAPIKey)
        #expect(store.currentAPIKey == nil)
    }

    @Test("All three tones produce distinct user messages for same input")
    func tonesProduceDistinctMessages() {
        let text = "Sample input text"
        var messages: Set<String> = []

        for tone in HumanizeTone.allCases {
            let message = HumanizeAPIService.buildUserMessage(text: text, tone: tone)
            messages.insert(message)
        }

        #expect(messages.count == HumanizeTone.allCases.count)
    }
}
