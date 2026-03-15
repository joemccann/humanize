import Foundation

public struct HumanizeAPIService: Sendable {
    private let httpClient: HTTPClient
    private static let cerebrasFallbackModel = "gpt-oss-120b"
    private static let openAIFallbackModel = "gpt-4o-mini"
    private static let anthropicFallbackModel = "claude-3-haiku-20240307"
    private static let modelCache = ModelCandidateCache()
    public static let defaultTimeoutSeconds: TimeInterval = 30

    public init(httpClient: HTTPClient = URLSession.shared) {
        self.httpClient = httpClient
    }

    /// Invalidate cached model candidates, e.g. when API keys change.
    public func invalidateModelCache() async {
        await Self.modelCache.invalidateAll()
    }

    public func humanize(
        text: String,
        tone: HumanizeTone,
        provider: AIProvider,
        apiKey: String
    ) async throws -> HumanizeResult {
        let start = ContinuousClock.now

        let userMessage = Self.buildUserMessage(text: text, tone: tone)
        let modelsToTry = await resolveModelCandidates(provider: provider, apiKey: apiKey)
        var lastError: HumanizeError?

        for (index, model) in modelsToTry.enumerated() {
            let request = Self.buildRequest(
                provider: provider,
                apiKey: apiKey,
                userMessage: userMessage,
                model: model
            )
            let (data, response) = try await performRequest(request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw HumanizeError.networkError("Invalid response")
            }

            guard httpResponse.statusCode == 200 else {
                let apiError = Self.parseAPIError(data: data, provider: provider, status: httpResponse.statusCode)
                let error = HumanizeError.apiError(status: httpResponse.statusCode, message: apiError.userMessage)
                lastError = error

                let hasAnotherModel = index < modelsToTry.count - 1
                if hasAnotherModel, shouldRetryWithNextModel(provider: provider, status: httpResponse.statusCode, apiError: apiError) {
                    continue
                }

                throw error
            }

            let parsed = try Self.parseResponse(data: data, provider: provider)
            let elapsed = start.duration(to: .now)
            let latencyMs = Int(elapsed.components.seconds * 1000 + elapsed.components.attoseconds / 1_000_000_000_000_000)

            return HumanizeResult(
                text: parsed.text,
                analysis: parsed.analysis,
                provider: provider,
                model: model,
                latencyMs: latencyMs
            )
        }

        throw lastError ?? HumanizeError.invalidResponse
    }

    // MARK: - Request building

    public static func buildUserMessage(text: String, tone: HumanizeTone) -> String {
        let options = """
        {
          "tone": "\(tone.rawValue)",
          "preserveMeaning": true
        }
        """
        return "Rewrite this text:\n\n\(text)\n\nOptions:\n\(options)"
    }

    public static func buildRequest(
        provider: AIProvider,
        apiKey: String,
        userMessage: String,
        model: String? = nil
    ) -> URLRequest {
        switch provider {
        case .cerebras:
            return buildCerebrasRequest(apiKey: apiKey, userMessage: userMessage, model: model ?? AIProvider.cerebras.defaultModel)
        case .openai:
            return buildOpenAIRequest(apiKey: apiKey, userMessage: userMessage, model: model ?? AIProvider.openai.defaultModel)
        case .anthropic:
            return buildAnthropicRequest(apiKey: apiKey, userMessage: userMessage, model: model ?? AIProvider.anthropic.defaultModel)
        }
    }

    // MARK: - Cerebras

    private static func buildCerebrasRequest(apiKey: String, userMessage: String, model: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.cerebras.ai/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = defaultTimeoutSeconds
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "stream": false,
            "messages": [
                ["role": "system", "content": humanizeSystemPrompt],
                ["role": "user", "content": userMessage],
            ],
            "temperature": 0.3,
            "top_p": 1,
            "max_completion_tokens": 1024,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - OpenAI

    private static func buildOpenAIRequest(apiKey: String, userMessage: String, model: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = defaultTimeoutSeconds
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": humanizeSystemPrompt],
                ["role": "user", "content": userMessage],
            ],
            "max_completion_tokens": 1024,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - Anthropic

    private static func buildAnthropicRequest(apiKey: String, userMessage: String, model: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.timeoutInterval = defaultTimeoutSeconds
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
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

    public static func parseResponse(data: Data, provider: AIProvider) throws -> (text: String, analysis: String?) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HumanizeError.invalidResponse
        }

        let rawText: String?

        switch provider {
        case .cerebras:
            let choices = json["choices"] as? [[String: Any]]
            let message = choices?.first?["message"] as? [String: Any]
            rawText = message?["content"] as? String

        case .openai:
            let choices = json["choices"] as? [[String: Any]]
            let message = choices?.first?["message"] as? [String: Any]
            rawText = message?["content"] as? String

        case .anthropic:
            let content = json["content"] as? [[String: Any]]
            let firstTextBlock = content?.first { $0["type"] as? String == "text" }
            rawText = firstTextBlock?["text"] as? String
        }

        guard let trimmed = rawText?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            throw HumanizeError.invalidResponse
        }

        return parseHumanizeResponse(trimmed)
    }

    // MARK: - Private helpers

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await httpClient.data(for: request)
        } catch {
            throw HumanizeError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Model resolution

    private func resolveModelCandidates(provider: AIProvider, apiKey: String) async -> [String] {
        let cacheKey = "\(provider.rawValue):\(apiKey)"
        if let cached = await Self.modelCache.get(cacheKey) {
            return cached
        }

        var models: [String] = [provider.defaultModel]

        switch provider {
        case .cerebras:
            models.append(Self.cerebrasFallbackModel)
        case .openai:
            if let latest = await fetchLatestOpenAIModel(apiKey: apiKey) {
                models.insert(latest, at: 0)
            }
            models.append(Self.openAIFallbackModel)
        case .anthropic:
            if let latest = await fetchLatestAnthropicModel(apiKey: apiKey) {
                models.insert(latest, at: 0)
            }
            models.append(Self.anthropicFallbackModel)
        }

        var uniqueModels: [String] = []
        for model in models where !model.isEmpty && !uniqueModels.contains(model) {
            uniqueModels.append(model)
        }

        await Self.modelCache.set(cacheKey, value: uniqueModels)
        return uniqueModels
    }

    private func fetchLatestOpenAIModel(apiKey: String) async -> String? {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await performRequest(request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["data"] as? [[String: Any]] else {
            return nil
        }

        return Self.selectLatestOpenAIModel(models: models)
    }

    private func fetchLatestAnthropicModel(apiKey: String) async -> String? {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/models")!)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        guard let (data, response) = try? await performRequest(request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["data"] as? [[String: Any]] else {
            return nil
        }

        return Self.selectLatestAnthropicModel(models: models)
    }

    public static func selectLatestOpenAIModel(models: [[String: Any]]) -> String? {
        let disallowedTokens = ["audio", "realtime", "transcribe", "tts", "search", "image", "embedding", "codex"]

        let filtered = models.filter { model in
            guard let id = model["id"] as? String else { return false }
            guard id.hasPrefix("gpt-") else { return false }
            return !disallowedTokens.contains { id.localizedCaseInsensitiveContains($0) }
        }

        let sorted = filtered.sorted { left, right in
            let leftCreated = left["created"] as? Int ?? 0
            let rightCreated = right["created"] as? Int ?? 0
            if leftCreated != rightCreated { return leftCreated > rightCreated }
            let leftID = left["id"] as? String ?? ""
            let rightID = right["id"] as? String ?? ""
            return leftID > rightID
        }

        return sorted.first?["id"] as? String
    }

    public static func selectLatestAnthropicModel(models: [[String: Any]]) -> String? {
        let filtered = models.filter { model in
            guard let id = model["id"] as? String else { return false }
            return id.hasPrefix("claude-")
        }

        let sorted = filtered.sorted { left, right in
            let leftCreated = left["created_at"] as? String ?? ""
            let rightCreated = right["created_at"] as? String ?? ""
            if leftCreated != rightCreated { return leftCreated > rightCreated }
            let leftID = left["id"] as? String ?? ""
            let rightID = right["id"] as? String ?? ""
            return leftID > rightID
        }

        return sorted.first?["id"] as? String
    }

    // MARK: - Error mapping

    private struct ParsedAPIError {
        let userMessage: String
        let code: String?
        let modelAvailabilityIssue: Bool
    }

    private static func parseAPIError(data: Data, provider: AIProvider, status: Int) -> ParsedAPIError {
        var providerMessage: String?
        var code: String?

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let errorObject = json["error"] as? [String: Any] {
                providerMessage = errorObject["message"] as? String
                code = (errorObject["code"] as? String) ?? (errorObject["type"] as? String)
            } else if let message = json["message"] as? String {
                providerMessage = message
                code = json["type"] as? String
            } else if let rawError = json["error"] as? String {
                providerMessage = rawError
            }
        } else if let rawBody = String(data: data, encoding: .utf8) {
            providerMessage = rawBody
        }

        providerMessage = providerMessage?
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let rawProviderMessage = providerMessage,
           rawProviderMessage.hasPrefix("{") || rawProviderMessage.hasPrefix("[") {
            providerMessage = nil
        }

        let lowerCode = code?.lowercased() ?? ""
        let lowerMessage = providerMessage?.lowercased() ?? ""
        let modelMissing = lowerCode.contains("model_not_found")
            || lowerCode.contains("not_found_error")
            || lowerMessage.contains("model")
                && (lowerMessage.contains("not found") || lowerMessage.contains("does not exist") || lowerMessage.contains("access"))

        if status == 401 {
            return ParsedAPIError(
                userMessage: "Authentication failed. Check your \(provider.displayName) API key in Settings.",
                code: code,
                modelAvailabilityIssue: modelMissing
            )
        }

        if status == 429 {
            return ParsedAPIError(
                userMessage: "Rate limit reached. Please wait a moment and try again.",
                code: code,
                modelAvailabilityIssue: modelMissing
            )
        }

        if status >= 500 {
            return ParsedAPIError(
                userMessage: "\(provider.displayName) is temporarily unavailable. Please try again.",
                code: code,
                modelAvailabilityIssue: modelMissing
            )
        }

        if modelMissing {
            return ParsedAPIError(
                userMessage: "The selected \(provider.displayName) model is not available for this API key.",
                code: code,
                modelAvailabilityIssue: modelMissing
            )
        }

        if let providerMessage, !providerMessage.isEmpty {
            return ParsedAPIError(userMessage: providerMessage, code: code, modelAvailabilityIssue: modelMissing)
        }

        return ParsedAPIError(
            userMessage: "Request failed with status \(status). Please try again.",
            code: code,
            modelAvailabilityIssue: modelMissing
        )
    }

    private func shouldRetryWithNextModel(provider: AIProvider, status: Int, apiError: ParsedAPIError) -> Bool {
        guard provider == .cerebras || provider == .openai || provider == .anthropic else { return false }
        guard status == 400 || status == 404 else { return false }
        if apiError.modelAvailabilityIssue { return true }

        let lowerCode = apiError.code?.lowercased() ?? ""
        return lowerCode.contains("model_not_found")
            || lowerCode.contains("not_found_error")
            || lowerCode.contains("invalid_request_error")
    }
}

private actor ModelCandidateCache {
    private struct Entry {
        let models: [String]
        let timestamp: ContinuousClock.Instant
    }

    private var values: [String: Entry] = [:]
    static let ttl: Duration = .seconds(3600)

    func get(_ key: String) -> [String]? {
        guard let entry = values[key] else { return nil }
        let elapsed = entry.timestamp.duration(to: .now)
        if elapsed > Self.ttl {
            values[key] = nil
            return nil
        }
        return entry.models
    }

    func set(_ key: String, value: [String]) {
        values[key] = Entry(models: value, timestamp: .now)
    }

    func invalidate(_ key: String) {
        values[key] = nil
    }

    func invalidateAll() {
        values.removeAll()
    }
}
