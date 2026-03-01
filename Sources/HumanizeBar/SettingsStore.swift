import Foundation
import SwiftUI

@Observable
@MainActor
final class SettingsStore {
    private static let toneKey = "humanize.tone"
    private static let providerKey = "humanize.provider"
    private static let cerebrasKeyKey = "humanize.cerebrasAPIKey"
    private static let openaiKeyKey = "humanize.openaiAPIKey"
    private static let anthropicKeyKey = "humanize.anthropicAPIKey"
    private static let appearanceKey = "humanize.appearance"

    private let defaults: UserDefaults

    var tone: HumanizeTone {
        didSet { defaults.set(tone.rawValue, forKey: Self.toneKey) }
    }

    var provider: AIProvider {
        didSet {
            normalizeProviderSelectionIfNeeded()
            defaults.set(provider.rawValue, forKey: Self.providerKey)
        }
    }

    var cerebrasAPIKey: String {
        didSet {
            defaults.set(cerebrasAPIKey, forKey: Self.cerebrasKeyKey)
            normalizeProviderSelectionIfNeeded()
        }
    }

    var openaiAPIKey: String {
        didSet {
            defaults.set(openaiAPIKey, forKey: Self.openaiKeyKey)
            normalizeProviderSelectionIfNeeded()
        }
    }

    var anthropicAPIKey: String {
        didSet {
            defaults.set(anthropicAPIKey, forKey: Self.anthropicKeyKey)
            normalizeProviderSelectionIfNeeded()
        }
    }

    var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Self.appearanceKey) }
    }

    var hasRequiredAPIKey: Bool {
        currentProviderForRequest != nil
    }

    var currentAPIKey: String? {
        guard let provider = currentProviderForRequest else { return nil }
        return apiKey(for: provider)
    }

    var currentProviderForRequest: AIProvider? {
        providerAttemptOrder.first { apiKey(for: $0) != nil }
    }

    var providerAttemptOrder: [AIProvider] {
        [provider] + provider.fallbackProviders
    }

    var selectableProviders: [AIProvider] {
        AIProvider.recommendedOrder.filter { hasAPIKey(for: $0) }
    }

    func apiKey(for provider: AIProvider) -> String? {
        switch provider {
        case .cerebras:
            sanitizedKey(cerebrasAPIKey)
        case .openai:
            sanitizedKey(openaiAPIKey)
        case .anthropic:
            sanitizedKey(anthropicAPIKey)
        }
    }

    func hasAPIKey(for provider: AIProvider) -> Bool {
        apiKey(for: provider) != nil
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.tone = defaults.string(forKey: Self.toneKey)
            .flatMap(HumanizeTone.init(rawValue:)) ?? .natural

        self.provider = defaults.string(forKey: Self.providerKey)
            .flatMap(AIProvider.init(rawValue:)) ?? .cerebras

        self.cerebrasAPIKey = defaults.string(forKey: Self.cerebrasKeyKey) ?? ""
        self.openaiAPIKey = defaults.string(forKey: Self.openaiKeyKey) ?? ""
        self.anthropicAPIKey = defaults.string(forKey: Self.anthropicKeyKey) ?? ""
        self.appearance = defaults.string(forKey: Self.appearanceKey)
            .flatMap(AppAppearance.init(rawValue:)) ?? .system

        normalizeProviderSelectionIfNeeded()
    }

    private func normalizeProviderSelectionIfNeeded() {
        guard !hasAPIKey(for: provider) else { return }
        guard let configuredProvider = selectableProviders.first else { return }
        guard configuredProvider != provider else { return }
        provider = configuredProvider
    }

    private func sanitizedKey(_ rawKey: String) -> String? {
        let trimmed = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
