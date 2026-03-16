import Foundation
import SwiftUI

// MARK: - Tone

public enum HumanizeTone: String, CaseIterable, Sendable, Codable {
    case natural
    case casual
    case professional
}

// MARK: - Provider

public enum AIProvider: String, CaseIterable, Sendable, Codable {
    case cerebras
    case openai
    case anthropic

    public static let recommendedOrder: [AIProvider] = [.cerebras, .openai, .anthropic]

    public var displayName: String {
        switch self {
        case .cerebras: "Cerebras"
        case .openai: "OpenAI"
        case .anthropic: "Anthropic"
        }
    }

    public var defaultModel: String {
        switch self {
        case .cerebras: "zai-glm-4.7"
        case .openai: "gpt-5.2-chat-latest"
        case .anthropic: "claude-sonnet-4-6"
        }
    }
}

// MARK: - Result

public struct HumanizeResult: Sendable {
    public let text: String
    public let analysis: String?
    public let provider: AIProvider
    public let model: String
    public let latencyMs: Int

    public init(text: String, analysis: String? = nil, provider: AIProvider, model: String, latencyMs: Int) {
        self.text = text
        self.analysis = analysis
        self.provider = provider
        self.model = model
        self.latencyMs = latencyMs
    }
}

// MARK: - Error

public enum HumanizeError: LocalizedError, Equatable {
    case noAPIKey
    case invalidResponse
    case networkError(String)
    case apiError(status: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .noAPIKey:
            "No API key configured for the selected provider."
        case .invalidResponse:
            "The API returned an empty or invalid response."
        case .networkError(let message):
            "Network error: \(message)"
        case .apiError(let status, let message):
            "API error (\(status)): \(message)"
        }
    }

    /// User-facing message suitable for display in status badges and alerts.
    public var userFacingDescription: String {
        switch self {
        case .noAPIKey:
            "Add at least one API key in Settings."
        case .invalidResponse:
            "The service returned an unreadable response. Please try again."
        case .networkError:
            "Couldn't connect to the provider. Check your internet connection and try again."
        case .apiError(_, let message):
            message
        }
    }

    /// Whether this error is critical enough to warrant an alert dialog (vs just a status badge).
    public var isCritical: Bool {
        switch self {
        case .networkError, .noAPIKey:
            true
        case .invalidResponse, .apiError:
            false
        }
    }
}
