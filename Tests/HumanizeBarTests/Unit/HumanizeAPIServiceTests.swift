import Testing
import Foundation
@testable import HumanizeBar

struct MockHTTPClient: HTTPClient, @unchecked Sendable {
    let handler: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await handler(request)
    }
}

func mockResponse(json: [String: Any], statusCode: Int = 200) -> (Data, URLResponse) {
    let data = try! JSONSerialization.data(withJSONObject: json)
    let response = HTTPURLResponse(
        url: URL(string: "https://example.com")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
    )!
    return (data, response)
}

@Suite("HumanizeAPIService")
struct HumanizeAPIServiceTests {
    // MARK: - Cerebras request format

    @Test("Cerebras request has correct URL, headers, and body")
    func cerebrasRequestFormat() {
        let request = HumanizeAPIService.buildRequest(
            provider: .cerebras,
            apiKey: "cbr-test",
            userMessage: "Rewrite this text:\n\nHello world"
        )

        #expect(request.url?.absoluteString == "https://api.cerebras.ai/v1/chat/completions")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer cbr-test")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == nil)
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == nil)

        let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        #expect(body["model"] as? String == "gpt-oss-120b")
        #expect(body["stream"] as? Bool == false)
        #expect(body["temperature"] as? Double == 0.3)
        #expect(body["top_p"] as? Int == 1)
        #expect(body["max_completion_tokens"] as? Int == 1024)

        let messages = body["messages"] as! [[String: Any]]
        #expect(messages.count == 2)
        #expect(messages[0]["role"] as? String == "system")
        #expect(messages[1]["role"] as? String == "user")
        #expect((messages[1]["content"] as? String)?.contains("Hello world") == true)
    }

    // MARK: - OpenAI request format

    @Test("OpenAI request has correct URL, headers, and body")
    func openaiRequestFormat() {
        let request = HumanizeAPIService.buildRequest(
            provider: .openai,
            apiKey: "sk-test",
            userMessage: "Rewrite this text:\n\nHello world"
        )

        #expect(request.url?.absoluteString == "https://api.openai.com/v1/chat/completions")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == nil)
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == nil)

        let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        #expect(body["model"] as? String == "gpt-4o-mini")
        #expect(body["temperature"] as? Double == 0.3)
        #expect(body["max_tokens"] as? Int == 1024)

        let messages = body["messages"] as! [[String: Any]]
        #expect(messages.count == 2)
        #expect(messages[0]["role"] as? String == "system")
        #expect(messages[1]["role"] as? String == "user")
        #expect((messages[1]["content"] as? String)?.contains("Hello world") == true)
    }

    // MARK: - Anthropic request format

    @Test("Anthropic request has correct URL, headers, and body")
    func anthropicRequestFormat() {
        let request = HumanizeAPIService.buildRequest(
            provider: .anthropic,
            apiKey: "ant-test",
            userMessage: "Rewrite this text:\n\nHello world"
        )

        #expect(request.url?.absoluteString == "https://api.anthropic.com/v1/messages")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "ant-test")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)

        let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        #expect(body["model"] as? String == AIProvider.anthropic.defaultModel)
        #expect(body["system"] as? String == humanizeSystemPrompt)
        #expect(body["max_tokens"] as? Int == 1024)

        let messages = body["messages"] as! [[String: Any]]
        #expect(messages.count == 1)
        #expect(messages[0]["role"] as? String == "user")
    }

    // MARK: - Response parsing

    @Test("Parses OpenAI response correctly")
    func parseOpenAI() throws {
        let json: [String: Any] = [
            "choices": [
                ["message": ["content": "Rewritten text here"]]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let result = try HumanizeAPIService.parseResponse(data: data, provider: .openai)
        #expect(result == "Rewritten text here")
    }

    @Test("Parses Cerebras response correctly")
    func parseCerebras() throws {
        let json: [String: Any] = [
            "choices": [
                ["message": ["content": "Rewritten text here"]]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let result = try HumanizeAPIService.parseResponse(data: data, provider: .cerebras)
        #expect(result == "Rewritten text here")
    }

    @Test("Parses Anthropic response correctly")
    func parseAnthropic() throws {
        let json: [String: Any] = [
            "content": [
                ["type": "text", "text": "Rewritten text here"]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let result = try HumanizeAPIService.parseResponse(data: data, provider: .anthropic)
        #expect(result == "Rewritten text here")
    }

    @Test("Parses Anthropic response when text block is not first")
    func parseAnthropicTextBlockAfterNonText() throws {
        let json: [String: Any] = [
            "content": [
                ["type": "thinking", "thinking": "internal"],
                ["type": "text", "text": "Rewritten text here"],
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let result = try HumanizeAPIService.parseResponse(data: data, provider: .anthropic)
        #expect(result == "Rewritten text here")
    }

    @Test("Parses first Anthropic text block when multiple are present")
    func parseAnthropicMultipleTextBlocks() throws {
        let json: [String: Any] = [
            "content": [
                ["type": "text", "text": "First text block"],
                ["type": "text", "text": "Second text block"],
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let result = try HumanizeAPIService.parseResponse(data: data, provider: .anthropic)
        #expect(result == "First text block")
    }

    @Test("Empty OpenAI response throws invalidResponse")
    func emptyOpenAIResponse() throws {
        let json: [String: Any] = ["choices": [["message": ["content": ""]]]]
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: HumanizeError.invalidResponse) {
            try HumanizeAPIService.parseResponse(data: data, provider: .openai)
        }
    }

    @Test("Empty Cerebras response throws invalidResponse")
    func emptyCerebrasResponse() throws {
        let json: [String: Any] = ["choices": [["message": ["content": ""]]]]
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: HumanizeError.invalidResponse) {
            try HumanizeAPIService.parseResponse(data: data, provider: .cerebras)
        }
    }

    @Test("Empty Anthropic response throws invalidResponse")
    func emptyAnthropicResponse() throws {
        let json: [String: Any] = ["content": [["type": "text", "text": ""]]]
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: HumanizeError.invalidResponse) {
            try HumanizeAPIService.parseResponse(data: data, provider: .anthropic)
        }
    }

    // MARK: - Full service flow with mock

    @Test("Successful OpenAI humanize call")
    func successfulOpenAICall() async throws {
        let client = MockHTTPClient { _ in
            mockResponse(json: [
                "choices": [["message": ["content": "Natural sounding text"]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "AI sounding text",
            tone: .natural,
            provider: .openai,
            apiKey: "sk-test"
        )

        #expect(result.text == "Natural sounding text")
        #expect(result.provider == .openai)
        #expect(result.model == "gpt-4o-mini")
        #expect(result.latencyMs >= 0)
    }

    @Test("Successful Cerebras humanize call")
    func successfulCerebrasCall() async throws {
        let client = MockHTTPClient { _ in
            mockResponse(json: [
                "choices": [["message": ["content": "Natural sounding text"]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "AI sounding text",
            tone: .natural,
            provider: .cerebras,
            apiKey: "cbr-test"
        )

        #expect(result.text == "Natural sounding text")
        #expect(result.provider == .cerebras)
        #expect(result.model == "gpt-oss-120b")
        #expect(result.latencyMs >= 0)
    }

    @Test("Successful Anthropic humanize call")
    func successfulAnthropicCall() async throws {
        let client = MockHTTPClient { _ in
            mockResponse(json: [
                "content": [["type": "text", "text": "Natural sounding text"]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "AI sounding text",
            tone: .casual,
            provider: .anthropic,
            apiKey: "ant-test"
        )

        #expect(result.text == "Natural sounding text")
        #expect(result.provider == .anthropic)
        #expect(result.model == AIProvider.anthropic.defaultModel)
    }

    @Test("HTTP 401 throws apiError")
    func http401Error() async throws {
        let client = MockHTTPClient { _ in
            mockResponse(json: ["error": "unauthorized"], statusCode: 401)
        }

        let service = HumanizeAPIService(httpClient: client)
        do {
            _ = try await service.humanize(
                text: "test", tone: .natural, provider: .openai, apiKey: "bad-key"
            )
            Issue.record("Expected HumanizeError.apiError")
        } catch let error as HumanizeError {
            if case .apiError(let status, _) = error {
                #expect(status == 401)
            } else {
                Issue.record("Expected apiError, got \(error)")
            }
        }
    }

    @Test("Network failure throws networkError")
    func networkFailure() async throws {
        let client = MockHTTPClient { _ in
            throw URLError(.notConnectedToInternet)
        }

        let service = HumanizeAPIService(httpClient: client)
        do {
            _ = try await service.humanize(
                text: "test", tone: .natural, provider: .openai, apiKey: "sk-test"
            )
            Issue.record("Expected HumanizeError.networkError")
        } catch let error as HumanizeError {
            if case .networkError = error {
                // Expected
            } else {
                Issue.record("Expected networkError, got \(error)")
            }
        }
    }

    // MARK: - Additional edge cases

    @Test("Malformed JSON throws invalidResponse")
    func malformedJSON() throws {
        let data = Data("not json".utf8)
        #expect(throws: HumanizeError.invalidResponse) {
            try HumanizeAPIService.parseResponse(data: data, provider: .openai)
        }
    }

    @Test("Missing choices key throws invalidResponse for OpenAI")
    func missingChoices() throws {
        let json: [String: Any] = ["data": "something"]
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: HumanizeError.invalidResponse) {
            try HumanizeAPIService.parseResponse(data: data, provider: .openai)
        }
    }

    @Test("Missing choices key throws invalidResponse for Cerebras")
    func missingCerebrasChoices() throws {
        let json: [String: Any] = ["data": "something"]
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: HumanizeError.invalidResponse) {
            try HumanizeAPIService.parseResponse(data: data, provider: .cerebras)
        }
    }

    @Test("Empty choices key throws invalidResponse for Cerebras")
    func emptyCerebrasChoices() throws {
        let json: [String: Any] = ["choices": []]
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: HumanizeError.invalidResponse) {
            try HumanizeAPIService.parseResponse(data: data, provider: .cerebras)
        }
    }

    @Test("Missing message object throws invalidResponse for Cerebras")
    func missingCerebrasMessage() throws {
        let json: [String: Any] = ["choices": [["delta": ["content": "value"]]]]
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: HumanizeError.invalidResponse) {
            try HumanizeAPIService.parseResponse(data: data, provider: .cerebras)
        }
    }

    @Test("Missing message content throws invalidResponse for Cerebras")
    func missingCerebrasMessageContent() throws {
        let json: [String: Any] = ["choices": [["message": [:]]]]
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: HumanizeError.invalidResponse) {
            try HumanizeAPIService.parseResponse(data: data, provider: .cerebras)
        }
    }

    @Test("Missing content key throws invalidResponse for Anthropic")
    func missingContent() throws {
        let json: [String: Any] = ["data": "something"]
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: HumanizeError.invalidResponse) {
            try HumanizeAPIService.parseResponse(data: data, provider: .anthropic)
        }
    }

    @Test("Anthropic response with wrong type field throws invalidResponse")
    func anthropicWrongType() throws {
        let json: [String: Any] = [
            "content": [["type": "image", "text": "ignored"]]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: HumanizeError.invalidResponse) {
            try HumanizeAPIService.parseResponse(data: data, provider: .anthropic)
        }
    }

    @Test("Whitespace-only response throws invalidResponse")
    func whitespaceOnlyResponse() throws {
        let json: [String: Any] = [
            "choices": [["message": ["content": "   \n  "]]]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: HumanizeError.invalidResponse) {
            try HumanizeAPIService.parseResponse(data: data, provider: .openai)
        }
    }

    @Test("Non-HTTPURLResponse throws networkError")
    func nonHTTPResponse() async throws {
        let client = MockHTTPClient { request in
            let data = Data()
            let response = URLResponse(
                url: request.url!,
                mimeType: nil,
                expectedContentLength: 0,
                textEncodingName: nil
            )
            return (data, response)
        }

        let service = HumanizeAPIService(httpClient: client)
        do {
            _ = try await service.humanize(
                text: "test", tone: .natural, provider: .openai, apiKey: "sk-test"
            )
            Issue.record("Expected HumanizeError.networkError")
        } catch let error as HumanizeError {
            if case .networkError = error {
                // Expected
            } else {
                Issue.record("Expected networkError, got \(error)")
            }
        }
    }

    @Test("HTTP 500 returns apiError with body")
    func http500Error() async throws {
        let client = MockHTTPClient { _ in
            mockResponse(json: ["error": "internal server error"], statusCode: 500)
        }

        let service = HumanizeAPIService(httpClient: client)
        do {
            _ = try await service.humanize(
                text: "test", tone: .natural, provider: .anthropic, apiKey: "ant-test"
            )
            Issue.record("Expected HumanizeError.apiError")
        } catch let error as HumanizeError {
            if case .apiError(let status, let message) = error {
                #expect(status == 500)
                #expect(message.contains("internal server error"))
            } else {
                Issue.record("Expected apiError, got \(error)")
            }
        }
    }

    @Test("HTTP 429 rate limit returns apiError")
    func http429Error() async throws {
        let client = MockHTTPClient { _ in
            mockResponse(json: ["error": "rate limited"], statusCode: 429)
        }

        let service = HumanizeAPIService(httpClient: client)
        do {
            _ = try await service.humanize(
                text: "test", tone: .casual, provider: .openai, apiKey: "sk-test"
            )
            Issue.record("Expected HumanizeError.apiError")
        } catch let error as HumanizeError {
            if case .apiError(let status, _) = error {
                #expect(status == 429)
            } else {
                Issue.record("Expected apiError, got \(error)")
            }
        }
    }

    @Test("Timeout error wraps as networkError")
    func timeoutError() async throws {
        let client = MockHTTPClient { _ in
            throw URLError(.timedOut)
        }

        let service = HumanizeAPIService(httpClient: client)
        do {
            _ = try await service.humanize(
                text: "test", tone: .professional, provider: .anthropic, apiKey: "ant-test"
            )
            Issue.record("Expected HumanizeError.networkError")
        } catch let error as HumanizeError {
            if case .networkError(let msg) = error {
                #expect(!msg.isEmpty)
            } else {
                Issue.record("Expected networkError, got \(error)")
            }
        }
    }

    @Test("Response with leading/trailing whitespace is trimmed")
    func responseWhitespaceTrimmed() throws {
        let json: [String: Any] = [
            "choices": [["message": ["content": "  trimmed result  \n"]]]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let result = try HumanizeAPIService.parseResponse(data: data, provider: .openai)
        #expect(result == "trimmed result")
    }

    @Test("OpenAI empty choices array throws invalidResponse")
    func emptyChoicesArray() throws {
        let json: [String: Any] = ["choices": []]
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: HumanizeError.invalidResponse) {
            try HumanizeAPIService.parseResponse(data: data, provider: .openai)
        }
    }

    @Test("Anthropic empty content array throws invalidResponse")
    func emptyContentArray() throws {
        let json: [String: Any] = ["content": []]
        let data = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: HumanizeError.invalidResponse) {
            try HumanizeAPIService.parseResponse(data: data, provider: .anthropic)
        }
    }

    @Test("Latency is non-negative for successful call")
    func latencyIsNonNegative() async throws {
        let client = MockHTTPClient { _ in
            mockResponse(json: [
                "choices": [["message": ["content": "result"]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "test", tone: .natural, provider: .openai, apiKey: "sk-test"
        )
        #expect(result.latencyMs >= 0)
    }
}
