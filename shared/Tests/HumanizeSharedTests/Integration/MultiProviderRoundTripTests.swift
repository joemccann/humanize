import Testing
import Foundation
@testable import HumanizeShared
import HumanizeTestSupport

@Suite("Multi-Provider Round Trip")
struct MultiProviderRoundTripTests {
    @Test("Same text, all tones, Cerebras - each produces valid result")
    func allTonesCerebras() async throws {
        let client = MockHTTPClient { request in
            if request.url?.path == "/v1/models" {
                return mockResponse(json: [
                    "data": [["id": "qwen-3-235b-a22b-instruct-2507", "created": 0]]
                ])
            }

            let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            let messages = body["messages"] as! [[String: Any]]
            let userContent = messages[1]["content"] as! String

            let tone: String
            if userContent.contains("\"natural\"") {
                tone = "natural"
            } else if userContent.contains("\"casual\"") {
                tone = "casual"
            } else {
                tone = "professional"
            }

            return mockResponse(json: [
                "choices": [["message": ["content": "Rewritten in \(tone) tone"]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)

        for tone in HumanizeTone.allCases {
            let result = try await service.humanize(
                text: "This is AI-generated text.",
                tone: tone,
                provider: .cerebras,
                apiKey: "cbr-test"
            )
            #expect(result.text.contains(tone.rawValue))
            #expect(result.provider == .cerebras)
            #expect(result.latencyMs >= 0)
        }
    }

    @Test("Same text, all tones, OpenAI — each produces valid result")
    func allTonesOpenAI() async throws {
        let client = MockHTTPClient { request in
            if request.url?.path == "/v1/models" {
                return mockResponse(json: [
                    "data": [["id": AIProvider.openai.defaultModel, "created": 1765344352]]
                ])
            }

            let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            let messages = body["messages"] as! [[String: Any]]
            let userContent = messages[1]["content"] as! String

            // Echo back which tone was requested
            let tone: String
            if userContent.contains("\"natural\"") {
                tone = "natural"
            } else if userContent.contains("\"casual\"") {
                tone = "casual"
            } else {
                tone = "professional"
            }

            return mockResponse(json: [
                "choices": [["message": ["content": "Rewritten in \(tone) tone"]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)

        for tone in HumanizeTone.allCases {
            let result = try await service.humanize(
                text: "This is AI-generated text.",
                tone: tone,
                provider: .openai,
                apiKey: "sk-test"
            )
            #expect(result.text.contains(tone.rawValue))
            #expect(result.provider == .openai)
            #expect(result.latencyMs >= 0)
        }
    }

    @Test("Same text, all tones, Anthropic — each produces valid result")
    func allTonesAnthropic() async throws {
        let client = MockHTTPClient { request in
            if request.url?.path == "/v1/models" {
                return mockResponse(json: [
                    "data": [["id": AIProvider.anthropic.defaultModel, "created_at": "2026-02-17T00:00:00Z"]]
                ])
            }

            let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            let messages = body["messages"] as! [[String: Any]]
            let userContent = messages[0]["content"] as! String

            let tone: String
            if userContent.contains("\"natural\"") {
                tone = "natural"
            } else if userContent.contains("\"casual\"") {
                tone = "casual"
            } else {
                tone = "professional"
            }

            return mockResponse(json: [
                "content": [["type": "text", "text": "Rewritten in \(tone) tone"]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)

        for tone in HumanizeTone.allCases {
            let result = try await service.humanize(
                text: "This is AI-generated text.",
                tone: tone,
                provider: .anthropic,
                apiKey: "ant-test"
            )
            #expect(result.text.contains(tone.rawValue))
            #expect(result.provider == .anthropic)
        }
    }

    @Test("Sequential calls to different providers return correct provider metadata")
    func sequentialProviderCalls() async throws {
        let client = MockHTTPClient { request in
            let host = request.url?.host ?? ""
            let path = request.url?.path ?? ""

            if host.contains("openai.com"), path == "/v1/models" {
                return mockResponse(json: [
                    "data": [["id": AIProvider.openai.defaultModel, "created": 1765344352]]
                ])
            }

            if host.contains("openai.com"), path == "/v1/chat/completions" {
                return mockResponse(json: [
                    "choices": [["message": ["content": "OpenAI result"]]]
                ])
            }

            if host.contains("anthropic.com"), path == "/v1/models" {
                return mockResponse(json: [
                    "data": [["id": AIProvider.anthropic.defaultModel, "created_at": "2026-02-17T00:00:00Z"]]
                ])
            }

            if host.contains("anthropic.com"), path == "/v1/messages" {
                return mockResponse(json: [
                    "content": [["type": "text", "text": "Anthropic result"]]
                ])
            }

            fatalError("Unexpected request: \(request.url?.absoluteString ?? "nil")")
        }

        let service = HumanizeAPIService(httpClient: client)

        let r1 = try await service.humanize(
            text: "test", tone: .natural, provider: .openai, apiKey: "sk-test"
        )
        #expect(r1.provider == .openai)
        #expect(r1.model == AIProvider.openai.defaultModel)

        let r2 = try await service.humanize(
            text: "test", tone: .natural, provider: .anthropic, apiKey: "ant-test"
        )
        #expect(r2.provider == .anthropic)
        #expect(r2.model == AIProvider.anthropic.defaultModel)
    }

    @Test("Request captures correct API key per provider")
    func apiKeyPerProvider() async throws {
        // Verify Cerebras auth header
        let cerebrasClient = MockHTTPClient { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer cbr-specific")
            if request.url?.path == "/v1/models" {
                return mockResponse(json: [
                    "data": [["id": "qwen-3-235b-a22b-instruct-2507", "created": 0]]
                ])
            }
            return mockResponse(json: [
                "choices": [["message": ["content": "ok"]]]
            ])
        }

        let cerebrasService = HumanizeAPIService(httpClient: cerebrasClient)
        _ = try await cerebrasService.humanize(
            text: "test", tone: .natural, provider: .cerebras, apiKey: "cbr-specific"
        )

        // Verify OpenAI auth header
        let openaiClient = MockHTTPClient { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-specific")
            if request.url?.path == "/v1/models" {
                return mockResponse(json: [
                    "data": [["id": AIProvider.openai.defaultModel, "created": 1765344352]]
                ])
            }
            return mockResponse(json: [
                "choices": [["message": ["content": "ok"]]]
            ])
        }

        let openaiService = HumanizeAPIService(httpClient: openaiClient)
        _ = try await openaiService.humanize(
            text: "test", tone: .natural, provider: .openai, apiKey: "sk-specific"
        )

        // Verify Anthropic x-api-key header
        let anthropicClient = MockHTTPClient { request in
            #expect(request.value(forHTTPHeaderField: "x-api-key") == "ant-specific")
            if request.url?.path == "/v1/models" {
                return mockResponse(json: [
                    "data": [["id": AIProvider.anthropic.defaultModel, "created_at": "2026-02-17T00:00:00Z"]]
                ])
            }
            return mockResponse(json: [
                "content": [["type": "text", "text": "ok"]]
            ])
        }

        let anthropicService = HumanizeAPIService(httpClient: anthropicClient)
        _ = try await anthropicService.humanize(
            text: "test", tone: .natural, provider: .anthropic, apiKey: "ant-specific"
        )
    }

    @Test("Large text input is included in request body")
    func largeTextInput() async throws {
        let largeText = String(repeating: "This is a sentence. ", count: 100)

        let client = MockHTTPClient { request in
            if request.url?.path == "/v1/models" {
                return mockResponse(json: [
                    "data": [["id": AIProvider.openai.defaultModel, "created": 1765344352]]
                ])
            }

            let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            let messages = body["messages"] as! [[String: Any]]
            let userContent = messages[1]["content"] as! String
            #expect(userContent.contains("This is a sentence."))

            return mockResponse(json: [
                "choices": [["message": ["content": "Shortened result"]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: largeText, tone: .natural, provider: .openai, apiKey: "sk-test"
        )
        #expect(result.text == "Shortened result")
    }
}
