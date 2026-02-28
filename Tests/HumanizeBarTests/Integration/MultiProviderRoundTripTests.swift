import Testing
import Foundation
@testable import HumanizeBar

@Suite("Multi-Provider Round Trip")
struct MultiProviderRoundTripTests {
    @Test("Same text, all tones, OpenAI — each produces valid result")
    func allTonesOpenAI() async throws {
        let client = MockHTTPClient { request in
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
            let url = request.url!.absoluteString
            if url.contains("openai") {
                return mockResponse(json: [
                    "choices": [["message": ["content": "OpenAI result"]]]
                ])
            } else {
                return mockResponse(json: [
                    "content": [["type": "text", "text": "Anthropic result"]]
                ])
            }
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
        // Verify OpenAI auth header
        let openaiClient = MockHTTPClient { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-specific")
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
