import Foundation

struct HumanizeAPIService: Sendable {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient = URLSession.shared) {
        self.httpClient = httpClient
    }

    func humanize(
        text: String,
        tone: HumanizeTone,
        provider: AIProvider,
        apiKey: String
    ) async throws -> HumanizeResult {
        let start = ContinuousClock.now

        let userMessage = buildUserMessage(text: text, tone: tone)
        let request = buildRequest(provider: provider, apiKey: apiKey, userMessage: userMessage)
        let (data, response) = try await performRequest(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HumanizeError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw HumanizeError.apiError(status: httpResponse.statusCode, message: body)
        }

        let resultText = try parseResponse(data: data, provider: provider)
        let elapsed = start.duration(to: .now)
        let latencyMs = Int(elapsed.components.seconds * 1000 + elapsed.components.attoseconds / 1_000_000_000_000_000)

        return HumanizeResult(
            text: resultText,
            provider: provider,
            model: provider.defaultModel,
            latencyMs: latencyMs
        )
    }

    // MARK: - Request building

    static func buildUserMessage(text: String, tone: HumanizeTone) -> String {
        let options = """
        {
          "tone": "\(tone.rawValue)",
          "preserveMeaning": true
        }
        """
        return "Rewrite this text:\n\n\(text)\n\nOptions:\n\(options)"
    }

    static func buildRequest(provider: AIProvider, apiKey: String, userMessage: String) -> URLRequest {
        switch provider {
        case .openai:
            return buildOpenAIRequest(apiKey: apiKey, userMessage: userMessage)
        case .anthropic:
            return buildAnthropicRequest(apiKey: apiKey, userMessage: userMessage)
        }
    }

    // MARK: - OpenAI

    private static func buildOpenAIRequest(apiKey: String, userMessage: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": AIProvider.openai.defaultModel,
            "messages": [
                ["role": "system", "content": humanizeSystemPrompt],
                ["role": "user", "content": userMessage],
            ],
            "temperature": 0.3,
            "max_tokens": 1024,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - Anthropic

    private static func buildAnthropicRequest(apiKey: String, userMessage: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": AIProvider.anthropic.defaultModel,
            "system": humanizeSystemPrompt,
            "messages": [
                ["role": "user", "content": userMessage],
            ],
            "max_tokens": 1024,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - Response parsing

    static func parseResponse(data: Data, provider: AIProvider) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HumanizeError.invalidResponse
        }

        let text: String?

        switch provider {
        case .openai:
            let choices = json["choices"] as? [[String: Any]]
            let message = choices?.first?["message"] as? [String: Any]
            text = message?["content"] as? String

        case .anthropic:
            let content = json["content"] as? [[String: Any]]
            if let first = content?.first, first["type"] as? String == "text" {
                text = first["text"] as? String
            } else {
                text = nil
            }
        }

        guard let result = text?.trimmingCharacters(in: .whitespacesAndNewlines), !result.isEmpty else {
            throw HumanizeError.invalidResponse
        }

        return result
    }

    // MARK: - Private helpers

    private func buildUserMessage(text: String, tone: HumanizeTone) -> String {
        Self.buildUserMessage(text: text, tone: tone)
    }

    private func buildRequest(provider: AIProvider, apiKey: String, userMessage: String) -> URLRequest {
        Self.buildRequest(provider: provider, apiKey: apiKey, userMessage: userMessage)
    }

    private func parseResponse(data: Data, provider: AIProvider) throws -> String {
        try Self.parseResponse(data: data, provider: provider)
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await httpClient.data(for: request)
        } catch {
            throw HumanizeError.networkError(error.localizedDescription)
        }
    }
}
