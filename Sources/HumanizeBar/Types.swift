import Foundation
import SwiftUI

// MARK: - Tone

enum HumanizeTone: String, CaseIterable, Sendable, Codable {
    case natural
    case casual
    case professional
}

// MARK: - Provider

enum AIProvider: String, CaseIterable, Sendable, Codable {
    case cerebras
    case openai
    case anthropic

    static let recommendedOrder: [AIProvider] = [.cerebras, .openai, .anthropic]

    var displayName: String {
        switch self {
        case .cerebras: "Cerebras"
        case .openai: "OpenAI"
        case .anthropic: "Anthropic"
        }
    }

    var defaultModel: String {
        switch self {
        case .cerebras: "zai-glm-4.7"
        case .openai: "gpt-5.2-chat-latest"
        case .anthropic: "claude-sonnet-4-6"
        }
    }
}

// MARK: - Result

struct HumanizeResult: Sendable {
    let text: String
    let provider: AIProvider
    let model: String
    let latencyMs: Int
}

// MARK: - Appearance

enum AppAppearance: String, CaseIterable, Sendable, Codable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    /// Always returns an explicit scheme — resolves "system" to the current OS appearance.
    @MainActor var resolvedColorScheme: ColorScheme {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system:
            NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? .dark : .light
        }
    }
}

// MARK: - Error

enum HumanizeError: LocalizedError, Equatable {
    case noAPIKey
    case invalidResponse
    case networkError(String)
    case apiError(status: Int, message: String)

    var errorDescription: String? {
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
}
