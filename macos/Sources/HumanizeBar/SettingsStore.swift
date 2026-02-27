import Foundation
import SwiftUI

@Observable
@MainActor
final class SettingsStore {
    private static let toneKey = "humanize.tone"
    private static let providerKey = "humanize.provider"
    private static let openaiKeyKey = "humanize.openaiAPIKey"
    private static let anthropicKeyKey = "humanize.anthropicAPIKey"

    private let defaults: UserDefaults

    var tone: HumanizeTone {
        didSet { defaults.set(tone.rawValue, forKey: Self.toneKey) }
    }

    var provider: AIProvider {
        didSet { defaults.set(provider.rawValue, forKey: Self.providerKey) }
    }

    var openaiAPIKey: String {
        didSet { defaults.set(openaiAPIKey, forKey: Self.openaiKeyKey) }
    }

    var anthropicAPIKey: String {
        didSet { defaults.set(anthropicAPIKey, forKey: Self.anthropicKeyKey) }
    }

    var hasRequiredAPIKey: Bool {
        guard let key = currentAPIKey else { return false }
        return !key.isEmpty
    }

    var currentAPIKey: String? {
        switch provider {
        case .openai:
            openaiAPIKey.isEmpty ? nil : openaiAPIKey
        case .anthropic:
            anthropicAPIKey.isEmpty ? nil : anthropicAPIKey
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.tone = defaults.string(forKey: Self.toneKey)
            .flatMap(HumanizeTone.init(rawValue:)) ?? .natural

        self.provider = defaults.string(forKey: Self.providerKey)
            .flatMap(AIProvider.init(rawValue:)) ?? .openai

        self.openaiAPIKey = defaults.string(forKey: Self.openaiKeyKey) ?? ""
        self.anthropicAPIKey = defaults.string(forKey: Self.anthropicKeyKey) ?? ""
    }
}
