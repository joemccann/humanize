import Testing
import Foundation
@testable import HumanizeBar

@Suite("Request Builder")
struct RequestBuilderTests {
    @Test("OpenAI body matches expected structure")
    func openaiBodyStructure() {
        let request = HumanizeAPIService.buildRequest(
            provider: .openai,
            apiKey: "sk-test",
            userMessage: "test message"
        )

        let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        #expect(body.keys.contains("model"))
        #expect(body.keys.contains("messages"))
        #expect(body.keys.contains("temperature"))
        #expect(body.keys.contains("max_tokens"))

        let messages = body["messages"] as! [[String: Any]]
        #expect(messages[0]["role"] as? String == "system")
        #expect(messages[0]["content"] as? String == humanizeSystemPrompt)
        #expect(messages[1]["role"] as? String == "user")
        #expect(messages[1]["content"] as? String == "test message")
    }

    @Test("Anthropic body matches expected structure")
    func anthropicBodyStructure() {
        let request = HumanizeAPIService.buildRequest(
            provider: .anthropic,
            apiKey: "ant-test",
            userMessage: "test message"
        )

        let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        #expect(body.keys.contains("model"))
        #expect(body.keys.contains("system"))
        #expect(body.keys.contains("messages"))
        #expect(body.keys.contains("max_tokens"))

        #expect(body["system"] as? String == humanizeSystemPrompt)
        let messages = body["messages"] as! [[String: Any]]
        #expect(messages.count == 1)
        #expect(messages[0]["role"] as? String == "user")
        #expect(messages[0]["content"] as? String == "test message")
    }

    @Test("System prompt is included in requests")
    func systemPromptIncluded() {
        let openaiReq = HumanizeAPIService.buildRequest(
            provider: .openai, apiKey: "key", userMessage: "msg"
        )
        let openaiBody = try! JSONSerialization.jsonObject(with: openaiReq.httpBody!) as! [String: Any]
        let messages = openaiBody["messages"] as! [[String: Any]]
        #expect(messages[0]["content"] as? String == humanizeSystemPrompt)

        let anthropicReq = HumanizeAPIService.buildRequest(
            provider: .anthropic, apiKey: "key", userMessage: "msg"
        )
        let anthropicBody = try! JSONSerialization.jsonObject(with: anthropicReq.httpBody!) as! [String: Any]
        #expect(anthropicBody["system"] as? String == humanizeSystemPrompt)
    }

    @Test("Each tone produces correct options in user message", arguments: HumanizeTone.allCases)
    func toneInUserMessage(tone: HumanizeTone) {
        let message = HumanizeAPIService.buildUserMessage(text: "test", tone: tone)
        #expect(message.contains("\"\(tone.rawValue)\""))
        #expect(message.contains("\"preserveMeaning\": true"))
        #expect(message.contains("Rewrite this text:"))
        #expect(message.contains("test"))
    }
}
