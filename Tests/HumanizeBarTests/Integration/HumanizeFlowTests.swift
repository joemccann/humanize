import Testing
import Foundation
@testable import HumanizeBar

@Suite("Humanize Flow")
struct HumanizeFlowTests {
    @Test("Full flow: input text → service → correct result")
    func fullFlow() async throws {
        let client = MockHTTPClient { request in
            let url = request.url!.absoluteString
            #expect(url == "https://api.openai.com/v1/chat/completions")

            return mockResponse(json: [
                "choices": [["message": ["content": "A naturally written sentence."]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "This is a very AI-sounding sentence that needs humanizing.",
            tone: .natural,
            provider: .openai,
            apiKey: "sk-test"
        )

        #expect(result.text == "A naturally written sentence.")
        #expect(result.provider == .openai)
        #expect(result.model == "gpt-4o-mini")
    }

    @Test("Error flow: service throws on API error")
    func errorFlow() async throws {
        let client = MockHTTPClient { _ in
            mockResponse(json: ["error": "bad request"], statusCode: 400)
        }

        let service = HumanizeAPIService(httpClient: client)
        do {
            _ = try await service.humanize(
                text: "test", tone: .natural, provider: .openai, apiKey: "sk-test"
            )
            Issue.record("Expected error")
        } catch let error as HumanizeError {
            if case .apiError(let status, _) = error {
                #expect(status == 400)
            } else {
                Issue.record("Expected apiError, got \(error)")
            }
        }
    }

    @Test("Provider switching uses different endpoint")
    func providerSwitching() async throws {
        let request = HumanizeAPIService.buildRequest(
            provider: .anthropic,
            apiKey: "ant-test",
            userMessage: "test"
        )
        #expect(request.url?.absoluteString == "https://api.anthropic.com/v1/messages")

        let client = MockHTTPClient { _ in
            mockResponse(json: [
                "content": [["type": "text", "text": "Anthropic output"]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "test",
            tone: .professional,
            provider: .anthropic,
            apiKey: "ant-test"
        )

        #expect(result.provider == .anthropic)
        #expect(result.text == "Anthropic output")
    }

    @Test("Different tones produce different request content")
    func toneVariations() async throws {
        for tone in HumanizeTone.allCases {
            let message = HumanizeAPIService.buildUserMessage(text: "Hello", tone: tone)
            #expect(message.contains(tone.rawValue))
        }
    }
}
