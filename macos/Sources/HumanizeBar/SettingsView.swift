import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var showOpenAIKey = false
    @State private var showAnthropicKey = false

    var body: some View {
        @Bindable var s = settings

        Form {
            Section("General") {
                Picker("Tone", selection: $s.tone) {
                    ForEach(HumanizeTone.allCases, id: \.self) { tone in
                        Text(tone.rawValue.capitalized).tag(tone)
                    }
                }

                Picker("Provider", selection: $s.provider) {
                    ForEach(AIProvider.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
            }

            Section("API Keys") {
                HStack {
                    if showOpenAIKey {
                        TextField("OpenAI API Key", text: $s.openaiAPIKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("OpenAI API Key", text: $s.openaiAPIKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    Button(action: { showOpenAIKey.toggle() }) {
                        Image(systemName: showOpenAIKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                    statusIcon(for: s.openaiAPIKey)
                }

                HStack {
                    if showAnthropicKey {
                        TextField("Anthropic API Key", text: $s.anthropicAPIKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("Anthropic API Key", text: $s.anthropicAPIKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    Button(action: { showAnthropicKey.toggle() }) {
                        Image(systemName: showAnthropicKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                    statusIcon(for: s.anthropicAPIKey)
                }
            }

            Section {
                HStack {
                    Text("Status:")
                        .foregroundStyle(.secondary)
                    if settings.hasRequiredAPIKey {
                        Label("Ready", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("Add a \(settings.provider.displayName) API key to get started",
                              systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 320)
    }

    private func statusIcon(for key: String) -> some View {
        Image(systemName: key.isEmpty ? "xmark.circle.fill" : "checkmark.circle.fill")
            .foregroundStyle(key.isEmpty ? .red : .green)
    }
}
