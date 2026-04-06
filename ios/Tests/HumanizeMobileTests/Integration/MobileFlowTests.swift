import Testing
import Foundation
@testable import HumanizeMobile
import HumanizeShared
import HumanizeTestSupport

@MainActor
@Suite("Mobile Flow")
struct MobileFlowTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("Full mobile humanize flow: settings → service → result")
    func fullFlow() async throws {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .cerebras
        store.cerebrasAPIKey = "cbr-mobile-test"
        store.tone = .natural

        #expect(store.hasRequiredAPIKey)

        let client = MockHTTPClient { request in
            #expect(request.url?.host == "api.cerebras.ai")
            if request.url?.path == "/v1/models" {
                return mockResponse(json: [
                    "data": [["id": "qwen-3-235b-a22b-instruct-2507", "created": 0]]
                ])
            }

            return mockResponse(json: [
                "choices": [["message": ["content": "Mobile humanized text"]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "AI-sounding text for mobile",
            tone: store.tone,
            provider: store.provider,
            apiKey: store.currentAPIKey!
        )

        #expect(result.text == "Mobile humanized text")
        #expect(result.provider == .cerebras)
        #expect(result.model == "qwen-3-235b-a22b-instruct-2507")
    }

    @Test("Settings configured for mobile → service uses correct provider")
    func providerRouting() async throws {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .anthropic
        store.anthropicAPIKey = "ant-mobile"

        let client = MockHTTPClient { request in
            #expect(request.url?.host == "api.anthropic.com")
            return mockResponse(json: [
                "content": [["type": "text", "text": "Anthropic mobile result"]]
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
        #expect(result.text == "Anthropic mobile result")
    }

    @Test("All tones work through mobile flow")
    func allTones() async throws {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .cerebras
        store.cerebrasAPIKey = "cbr-test"

        let client = MockHTTPClient { request in
            if request.url?.path == "/v1/models" {
                return mockResponse(json: [
                    "data": [["id": "qwen-3-235b-a22b-instruct-2507", "created": 0]]
                ])
            }

            let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            let messages = body["messages"] as! [[String: Any]]
            let content = messages[1]["content"] as! String

            let tone: String
            if content.contains("\"natural\"") { tone = "natural" }
            else if content.contains("\"casual\"") { tone = "casual" }
            else { tone = "professional" }

            return mockResponse(json: [
                "choices": [["message": ["content": "Rewritten in \(tone) tone"]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)

        for tone in HumanizeTone.allCases {
            store.tone = tone
            let result = try await service.humanize(
                text: "test text",
                tone: store.tone,
                provider: store.provider,
                apiKey: store.currentAPIKey!
            )
            #expect(result.text.contains(tone.rawValue))
        }
    }

    @Test("Clipboard copy can be called with humanize result")
    func clipboardIntegration() async throws {
        let client = MockHTTPClient { request in
            if request.url?.path == "/v1/models" {
                return mockResponse(json: [
                    "data": [["id": "qwen-3-235b-a22b-instruct-2507", "created": 0]]
                ])
            }

            return mockResponse(json: [
                "choices": [["message": ["content": "Clipboard test result"]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "test",
            tone: .natural,
            provider: .cerebras,
            apiKey: "cbr-test"
        )

        #expect(result.text == "Clipboard test result")
        // UIPasteboard may not be available in simulator test sandbox
        MobileClipboard.copy(result.text)
    }

    @Test("ViewModel end-to-end: settings → service → result state")
    func viewModelEndToEnd() async throws {
        let store = SettingsStore(defaults: freshDefaults())
        store.provider = .cerebras
        store.cerebrasAPIKey = "cbr-e2e"
        store.tone = .casual

        let client = MockHTTPClient { request in
            #expect(request.url?.host == "api.cerebras.ai")
            if request.url?.path == "/v1/models" {
                return mockResponse(json: [
                    "data": [["id": "qwen-3-235b-a22b-instruct-2507", "created": 0]]
                ])
            }

            let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            let messages = body["messages"] as! [[String: Any]]
            let content = messages[1]["content"] as! String
            #expect(content.contains("casual"))
            return mockResponse(json: [
                "choices": [["message": ["content": "Chill version of the text"]]]
            ])
        }

        let vm = HumanizeViewModel(service: HumanizeAPIService(httpClient: client))
        vm.inputText = "Very formal AI text"
        vm.humanize(settings: store)

        try await Task.sleep(for: .milliseconds(150))

        #expect(vm.outputText == "Chill version of the text")
        #expect(vm.outputVisible == true)
        #expect(vm.isProcessing == false)
        #expect(vm.statusKind == .success)
    }
}
