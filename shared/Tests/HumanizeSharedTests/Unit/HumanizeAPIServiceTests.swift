import Testing
import Foundation
@testable import HumanizeShared
import HumanizeTestSupport

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
        #expect(body["model"] as? String == "zai-glm-4.7")
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
        #expect(body["model"] as? String == AIProvider.openai.defaultModel)
        #expect(body["max_completion_tokens"] as? Int == 1024)
        #expect(body["max_tokens"] == nil)
        #expect(body["temperature"] == nil)

        let messages = body["messages"] as! [[String: Any]]
        #expect(messages.count == 2)
        #expect(messages[0]["role"] as? String == "system")
        #expect(messages[1]["role"] as? String == "user")
        #expect((messages[1]["content"] as? String)?.contains("Hello world") == true)
    }

    @Test("OpenAI GPT-5 request omits unsupported temperature parameter")
    func openAIGPT5OmitsTemperature() {
        let request = HumanizeAPIService.buildRequest(
            provider: .openai,
            apiKey: "sk-test",
            userMessage: "Rewrite this text:\n\nHello world",
            model: "gpt-5.2-chat-latest"
        )

        let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        #expect(body["temperature"] == nil)
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

    @Test("Selects latest compatible OpenAI model from model list")
    func selectLatestOpenAIModel() {
        let models: [[String: Any]] = [
            ["id": "gpt-realtime-1.5", "created": 1000],
            ["id": "gpt-5.2-chat-latest", "created": 3000],
            ["id": "gpt-5.3-codex", "created": 4000],
            ["id": "gpt-4o-mini", "created": 2000],
        ]

        let selected = HumanizeAPIService.selectLatestOpenAIModel(models: models)
        #expect(selected == "gpt-5.2-chat-latest")
    }

    @Test("Selects latest Anthropic model from model list")
    func selectLatestAnthropicModel() {
        let models: [[String: Any]] = [
            ["id": "claude-opus-4-6", "created_at": "2026-02-04T00:00:00Z"],
            ["id": "claude-sonnet-4-6", "created_at": "2026-02-17T00:00:00Z"],
            ["id": "claude-3-haiku-20240307", "created_at": "2024-03-07T00:00:00Z"],
        ]

        let selected = HumanizeAPIService.selectLatestAnthropicModel(models: models)
        #expect(selected == "claude-sonnet-4-6")
    }

    @Test("Selects best available Cerebras models from live model list")
    func selectCerebrasModels() {
        let models: [[String: Any]] = [
            ["id": "llama3.1-8b", "created": 0],
            ["id": "qwen-3-235b-a22b-instruct-2507", "created": 0],
            ["id": "multimodal-image-preview", "created": 999],
        ]

        let selected = HumanizeAPIService.selectCerebrasModels(models: models)
        #expect(selected == ["qwen-3-235b-a22b-instruct-2507", "llama3.1-8b"])
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
        #expect(result.text == "Rewritten text here")
        #expect(result.analysis == nil)
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
        #expect(result.text == "Rewritten text here")
        #expect(result.analysis == nil)
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
        #expect(result.text == "Rewritten text here")
        #expect(result.analysis == nil)
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
        #expect(result.text == "Rewritten text here")
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
        #expect(result.text == "First text block")
    }

    @Test("parseResponse extracts analysis from structured response")
    func parseResponseWithAnalysis() throws {
        let json: [String: Any] = [
            "choices": [
                ["message": ["content": "Clean text.\n---\nOveruse of em-dashes."]]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let result = try HumanizeAPIService.parseResponse(data: data, provider: .openai)
        #expect(result.text == "Clean text.")
        #expect(result.analysis == "Overuse of em-dashes.")
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
            return mockResponse(json: [
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
        #expect(result.model == AIProvider.openai.defaultModel)
        #expect(result.latencyMs >= 0)
    }

    @Test("OpenAI falls back to compatibility model when selected model is unavailable")
    func openAIModelFallback() async throws {
        let client = MockHTTPClient { request in
            let path = request.url?.path ?? ""

            if path == "/v1/models" {
                return mockResponse(json: [
                    "data": [
                        ["id": AIProvider.openai.defaultModel, "created": 3000],
                        ["id": "gpt-4o-mini", "created": 2000],
                    ]
                ])
            }

            let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            let model = body["model"] as! String

            if model == AIProvider.openai.defaultModel {
                return mockResponse(json: [
                    "error": [
                        "message": "The model does not exist or you do not have access to it.",
                        "type": "invalid_request_error",
                        "code": "model_not_found",
                    ]
                ], statusCode: 404)
            }

            #expect(model == "gpt-4o-mini")
            return mockResponse(json: [
                "choices": [["message": ["content": "Fallback model result"]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "AI sounding text",
            tone: .natural,
            provider: .openai,
            apiKey: "sk-test"
        )

        #expect(result.provider == .openai)
        #expect(result.model == "gpt-4o-mini")
        #expect(result.text == "Fallback model result")
    }

    @Test("Anthropic falls back when model-not-found has no explicit error code")
    func anthropicModelFallbackWithoutErrorCode() async throws {
        let client = MockHTTPClient { request in
            let path = request.url?.path ?? ""

            if path == "/v1/models" {
                return mockResponse(json: [
                    "data": [
                        ["id": AIProvider.anthropic.defaultModel, "created_at": "2026-02-17T00:00:00Z"],
                        ["id": "claude-3-haiku-20240307", "created_at": "2024-03-07T00:00:00Z"],
                    ]
                ])
            }

            let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            let model = body["model"] as! String

            if model == AIProvider.anthropic.defaultModel {
                return mockResponse(json: [
                    "error": [
                        "message": "The model '\(AIProvider.anthropic.defaultModel)' does not exist or is unavailable.",
                    ],
                ], statusCode: 404)
            }

            #expect(model == "claude-3-haiku-20240307")
            return mockResponse(json: [
                "content": [["type": "text", "text": "Anthropic fallback result"]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "AI sounding text",
            tone: .natural,
            provider: .anthropic,
            apiKey: "ant-fallback-test"
        )

        #expect(result.provider == .anthropic)
        #expect(result.model == "claude-3-haiku-20240307")
        #expect(result.text == "Anthropic fallback result")
    }

    @Test("API error messages are human-friendly, not raw payloads")
    func apiErrorMessageIsFriendly() async throws {
        let client = MockHTTPClient { request in
            let path = request.url?.path ?? ""
            if path == "/v1/models" {
                return mockResponse(json: [
                    "data": [["id": "claude-sonnet-4-6", "created_at": "2026-02-17T00:00:00Z"]]
                ])
            }

            return mockResponse(json: [
                "type": "error",
                "error": [
                    "type": "not_found_error",
                    "message": "The model 'claude-x' does not exist.",
                ],
            ], statusCode: 404)
        }

        let service = HumanizeAPIService(httpClient: client)
        do {
            _ = try await service.humanize(
                text: "test",
                tone: .natural,
                provider: .anthropic,
                apiKey: "ant-test"
            )
            Issue.record("Expected HumanizeError.apiError")
        } catch let error as HumanizeError {
            if case .apiError(let status, let message) = error {
                #expect(status == 404)
                #expect(!message.contains("{"))
                #expect(message.contains("model"))
            } else {
                Issue.record("Expected apiError, got \(error)")
            }
        }
    }

    @Test("Successful Cerebras humanize call")
    func successfulCerebrasCall() async throws {
        let client = MockHTTPClient { request in
            if request.url?.path == "/v1/models" {
                return mockResponse(json: [
                    "data": [
                        ["id": "qwen-3-235b-a22b-instruct-2507", "created": 0]
                    ]
                ])
            }

            return mockResponse(json: [
                "choices": [["message": ["content": "Natural sounding text"]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "AI sounding text",
            tone: .natural,
            provider: .cerebras,
            apiKey: "cbr-success-test"
        )

        #expect(result.text == "Natural sounding text")
        #expect(result.provider == .cerebras)
        #expect(result.model == "qwen-3-235b-a22b-instruct-2507")
        #expect(result.latencyMs >= 0)
    }

    @Test("Cerebras uses discovered model catalog before hardcoded fallbacks")
    func cerebrasUsesDiscoveredModelsFirst() async throws {
        let modelsRequested = RequestedModels()
        let client = MockHTTPClient { request in
            let path = request.url?.path ?? ""
            if path == "/v1/models" {
                return mockResponse(json: [
                    "data": [
                        ["id": "llama3.1-8b", "created": 0],
                        ["id": "qwen-3-235b-a22b-instruct-2507", "created": 0],
                    ]
                ])
            }

            let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            let model = body["model"] as! String
            await modelsRequested.append(model)
            #expect(model == "qwen-3-235b-a22b-instruct-2507")

            return mockResponse(json: [
                "choices": [["message": ["content": "Catalog-selected result"]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "AI sounding text",
            tone: .natural,
            provider: .cerebras,
            apiKey: "cbr-catalog-test"
        )

        #expect(result.provider == .cerebras)
        #expect(result.model == "qwen-3-235b-a22b-instruct-2507")
        #expect(result.text == "Catalog-selected result")
        let models = await modelsRequested.values
        #expect(models == ["qwen-3-235b-a22b-instruct-2507"])
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

    @Test("HTTP 500 returns friendly availability error")
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
                #expect(message == "Anthropic is temporarily unavailable. Please try again.")
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
        #expect(result.text == "trimmed result")
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

    // MARK: - Cerebras model fallback

    @Test("Cerebras model_not_found falls back to gpt-oss-120b")
    func cerebrasModelFallback() async throws {
        let modelsRequested = RequestedModels()
        let client = MockHTTPClient { request in
            let path = request.url?.path ?? ""
            if path == "/v1/models" {
                return mockResponse(json: [
                    "data": [
                        ["id": AIProvider.cerebras.defaultModel, "created": 2000],
                        ["id": "gpt-oss-120b", "created": 1000],
                    ]
                ])
            }

            let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            let model = body["model"] as! String
            await modelsRequested.append(model)

            if model == "zai-glm-4.7" {
                return mockResponse(json: [
                    "error": ["message": "Model zai-glm-4.7 does not exist", "type": "not_found_error", "code": "model_not_found"]
                ], statusCode: 404)
            }

            // gpt-oss-120b succeeds
            return mockResponse(json: [
                "choices": [["message": ["content": "Fallback result"]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)
        let result = try await service.humanize(
            text: "test", tone: .natural, provider: .cerebras, apiKey: "cbr-fallback-test"
        )

        #expect(result.text == "Fallback result")
        #expect(result.provider == .cerebras)
        #expect(result.model == "gpt-oss-120b")
        let models = await modelsRequested.values
        #expect(models == ["zai-glm-4.7", "gpt-oss-120b"])
    }
}

private actor RequestedModels {
    var values: [String] = []

    func append(_ model: String) {
        values.append(model)
    }
}
