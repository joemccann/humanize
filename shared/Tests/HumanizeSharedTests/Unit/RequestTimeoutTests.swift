import Testing
import Foundation
@testable import HumanizeShared

@Suite("Request timeout")
struct RequestTimeoutTests {
    @Test("Cerebras request has timeout set")
    func cerebrasTimeout() {
        let request = HumanizeAPIService.buildRequest(
            provider: .cerebras, apiKey: "key", userMessage: "msg"
        )
        #expect(request.timeoutInterval == HumanizeAPIService.defaultTimeoutSeconds)
    }

    @Test("OpenAI request has timeout set")
    func openAITimeout() {
        let request = HumanizeAPIService.buildRequest(
            provider: .openai, apiKey: "key", userMessage: "msg"
        )
        #expect(request.timeoutInterval == HumanizeAPIService.defaultTimeoutSeconds)
    }

    @Test("Anthropic request has timeout set")
    func anthropicTimeout() {
        let request = HumanizeAPIService.buildRequest(
            provider: .anthropic, apiKey: "key", userMessage: "msg"
        )
        #expect(request.timeoutInterval == HumanizeAPIService.defaultTimeoutSeconds)
    }

    @Test("Default timeout is 30 seconds")
    func defaultValue() {
        #expect(HumanizeAPIService.defaultTimeoutSeconds == 30)
    }
}
