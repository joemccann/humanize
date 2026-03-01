import Testing
import Foundation
@testable import HumanizeBar

@Suite("HumanizeTone")
struct HumanizeToneTests {
    @Test("allCases contains exactly 3 tones")
    func allCases() {
        #expect(HumanizeTone.allCases.count == 3)
        #expect(HumanizeTone.allCases.contains(.natural))
        #expect(HumanizeTone.allCases.contains(.casual))
        #expect(HumanizeTone.allCases.contains(.professional))
    }

    @Test("Raw values are lowercase strings", arguments: HumanizeTone.allCases)
    func rawValues(tone: HumanizeTone) {
        #expect(tone.rawValue == tone.rawValue.lowercased())
        #expect(!tone.rawValue.isEmpty)
    }

    @Test("Round-trips through rawValue", arguments: HumanizeTone.allCases)
    func roundTrip(tone: HumanizeTone) {
        let restored = HumanizeTone(rawValue: tone.rawValue)
        #expect(restored == tone)
    }

    @Test("Invalid raw value returns nil")
    func invalidRawValue() {
        #expect(HumanizeTone(rawValue: "aggressive") == nil)
        #expect(HumanizeTone(rawValue: "") == nil)
    }

    @Test("Conforms to Codable — encode and decode", arguments: HumanizeTone.allCases)
    func codable(tone: HumanizeTone) throws {
        let data = try JSONEncoder().encode(tone)
        let decoded = try JSONDecoder().decode(HumanizeTone.self, from: data)
        #expect(decoded == tone)
    }
}

@Suite("AIProvider")
struct AIProviderTests {
    @Test("allCases contains exactly 3 providers")
    func allCases() {
        #expect(AIProvider.allCases.count == 3)
        #expect(AIProvider.allCases.contains(.cerebras))
        #expect(AIProvider.allCases.contains(.openai))
        #expect(AIProvider.allCases.contains(.anthropic))
    }

    @Test("displayName returns human-readable name")
    func displayNames() {
        #expect(AIProvider.cerebras.displayName == "Cerebras")
        #expect(AIProvider.openai.displayName == "OpenAI")
        #expect(AIProvider.anthropic.displayName == "Anthropic")
    }

    @Test("defaultModel returns expected model IDs")
    func defaultModels() {
        #expect(AIProvider.cerebras.defaultModel == "gpt-oss-120b")
        #expect(AIProvider.openai.defaultModel == "gpt-5.2-chat-latest")
        #expect(AIProvider.anthropic.defaultModel == "claude-sonnet-4-6")
    }

    @Test("recommended order starts with Cerebras")
    func recommendedOrder() {
        #expect(AIProvider.recommendedOrder == [.cerebras, .openai, .anthropic])
    }

    @Test("fallbackProviders preserves recommended order excluding self", arguments: AIProvider.allCases)
    func fallbackProviders(provider: AIProvider) {
        let expected = AIProvider.recommendedOrder.filter { $0 != provider }
        #expect(provider.fallbackProviders == expected)
    }

    @Test("recommended order includes all providers exactly once")
    func recommendedOrderCompleteness() {
        #expect(AIProvider.recommendedOrder.count == AIProvider.allCases.count)
        #expect(Set(AIProvider.recommendedOrder) == Set(AIProvider.allCases))
    }

    @Test("Round-trips through rawValue", arguments: AIProvider.allCases)
    func roundTrip(provider: AIProvider) {
        let restored = AIProvider(rawValue: provider.rawValue)
        #expect(restored == provider)
    }

    @Test("Invalid raw value returns nil")
    func invalidRawValue() {
        #expect(AIProvider(rawValue: "google") == nil)
    }

    @Test("Conforms to Codable — encode and decode", arguments: AIProvider.allCases)
    func codable(provider: AIProvider) throws {
        let data = try JSONEncoder().encode(provider)
        let decoded = try JSONDecoder().decode(AIProvider.self, from: data)
        #expect(decoded == provider)
    }
}

@Suite("AppAppearance")
struct AppAppearanceTests {
    @Test("allCases contains exactly 3 modes")
    func allCases() {
        #expect(AppAppearance.allCases.count == 3)
        #expect(AppAppearance.allCases.contains(.system))
        #expect(AppAppearance.allCases.contains(.light))
        #expect(AppAppearance.allCases.contains(.dark))
    }

    @Test("colorScheme returns nil for system, explicit for others")
    func colorScheme() {
        #expect(AppAppearance.system.colorScheme == nil)
        #expect(AppAppearance.light.colorScheme == .light)
        #expect(AppAppearance.dark.colorScheme == .dark)
    }

    @Test("Round-trips through rawValue", arguments: AppAppearance.allCases)
    func roundTrip(appearance: AppAppearance) {
        let restored = AppAppearance(rawValue: appearance.rawValue)
        #expect(restored == appearance)
    }

    @Test("Invalid raw value returns nil")
    func invalidRawValue() {
        #expect(AppAppearance(rawValue: "auto") == nil)
    }

    @Test("Conforms to Codable — encode and decode", arguments: AppAppearance.allCases)
    func codable(appearance: AppAppearance) throws {
        let data = try JSONEncoder().encode(appearance)
        let decoded = try JSONDecoder().decode(AppAppearance.self, from: data)
        #expect(decoded == appearance)
    }
}

@Suite("HumanizeError")
struct HumanizeErrorTests {
    @Test("noAPIKey has correct description")
    func noAPIKey() {
        let error = HumanizeError.noAPIKey
        #expect(error.errorDescription?.contains("No API key") == true)
    }

    @Test("invalidResponse has correct description")
    func invalidResponse() {
        let error = HumanizeError.invalidResponse
        #expect(error.errorDescription?.contains("empty or invalid") == true)
    }

    @Test("networkError includes message")
    func networkError() {
        let error = HumanizeError.networkError("Connection refused")
        #expect(error.errorDescription?.contains("Connection refused") == true)
        #expect(error.errorDescription?.contains("Network error") == true)
    }

    @Test("apiError includes status code and message")
    func apiError() {
        let error = HumanizeError.apiError(status: 429, message: "Rate limited")
        #expect(error.errorDescription?.contains("429") == true)
        #expect(error.errorDescription?.contains("Rate limited") == true)
    }

    @Test("Equatable: same errors are equal")
    func equatable() {
        #expect(HumanizeError.noAPIKey == HumanizeError.noAPIKey)
        #expect(HumanizeError.invalidResponse == HumanizeError.invalidResponse)
        #expect(HumanizeError.networkError("a") == HumanizeError.networkError("a"))
        #expect(HumanizeError.apiError(status: 500, message: "x") == HumanizeError.apiError(status: 500, message: "x"))
    }

    @Test("Equatable: different errors are not equal")
    func notEqual() {
        #expect(HumanizeError.noAPIKey != HumanizeError.invalidResponse)
        #expect(HumanizeError.networkError("a") != HumanizeError.networkError("b"))
        #expect(HumanizeError.apiError(status: 400, message: "x") != HumanizeError.apiError(status: 500, message: "x"))
        #expect(HumanizeError.apiError(status: 400, message: "a") != HumanizeError.apiError(status: 400, message: "b"))
    }
}

@Suite("HumanizeResult")
struct HumanizeResultTests {
    @Test("Stores all fields correctly")
    func fields() {
        let result = HumanizeResult(text: "output", provider: .cerebras, model: "gpt-oss-120b", latencyMs: 150)
        #expect(result.text == "output")
        #expect(result.provider == .cerebras)
        #expect(result.model == "gpt-oss-120b")
        #expect(result.latencyMs == 150)
    }

    @Test("Anthropic result fields")
    func anthropicResult() {
        let result = HumanizeResult(text: "rewritten", provider: .anthropic, model: AIProvider.anthropic.defaultModel, latencyMs: 300)
        #expect(result.provider == .anthropic)
        #expect(result.model == AIProvider.anthropic.defaultModel)
    }
}
