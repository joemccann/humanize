import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var showOpenAIKey = false
    @State private var showAnthropicKey = false

    var body: some View {
        @Bindable var s = settings

        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.878, green: 0.949, blue: 0.996))
                        .frame(width: 28, height: 28)
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(red: 0.012, green: 0.412, blue: 0.624))
                }
                Text("Humanize Settings")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 16)

            Form {
                Section {
                    Picker("Default Tone", selection: $s.tone) {
                        ForEach(HumanizeTone.allCases, id: \.self) { tone in
                            Text(tone.rawValue.capitalized).tag(tone)
                        }
                    }

                    Picker("Provider", selection: $s.provider) {
                        ForEach(AIProvider.allCases, id: \.self) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                } header: {
                    Text("General")
                        .font(.system(size: 10, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                }

                Section {
                    HStack(spacing: 6) {
                        if showOpenAIKey {
                            TextField("sk-...", text: $s.openaiAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12, design: .monospaced))
                        } else {
                            SecureField("sk-...", text: $s.openaiAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12))
                        }
                        Button(action: { showOpenAIKey.toggle() }) {
                            Image(systemName: showOpenAIKey ? "eye.slash" : "eye")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        statusDot(for: s.openaiAPIKey)
                    }

                    HStack(spacing: 6) {
                        if showAnthropicKey {
                            TextField("sk-ant-...", text: $s.anthropicAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12, design: .monospaced))
                        } else {
                            SecureField("sk-ant-...", text: $s.anthropicAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12))
                        }
                        Button(action: { showAnthropicKey.toggle() }) {
                            Image(systemName: showAnthropicKey ? "eye.slash" : "eye")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        statusDot(for: s.anthropicAPIKey)
                    }
                } header: {
                    Text("API Keys")
                        .font(.system(size: 10, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                }

                // Status row
                Section {
                    HStack(spacing: 6) {
                        if settings.hasRequiredAPIKey {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 12))
                            Text("Ready to humanize")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.system(size: 12))
                            Text("Add a \(settings.provider.displayName) API key")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 420, height: 340)
    }

    private func statusDot(for key: String) -> some View {
        Circle()
            .fill(key.isEmpty ? Color.red.opacity(0.6) : Color.green.opacity(0.7))
            .frame(width: 8, height: 8)
    }
}
