#if os(macOS)
import SwiftUI
import KeyboardShortcuts
import HumanizeShared

/// Settings view for the launcher app.
/// Includes a `KeyboardShortcuts.Recorder` so users can define their own global hotkey.
struct LauncherSettingsView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        @Bindable var s = settings

        Form {
            Section {
                KeyboardShortcuts.Recorder("Toggle Panel:", name: .togglePanel)
            } header: {
                Text("Global Shortcut")
            }

            Section {
                Picker("Default Tone", selection: $s.tone) {
                    ForEach(HumanizeTone.allCases, id: \.self) { tone in
                        Text(tone.rawValue.capitalized).tag(tone)
                    }
                }

                Picker("Provider", selection: $s.provider) {
                    ForEach(s.selectableProviders.isEmpty ? AIProvider.allCases : s.selectableProviders, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .disabled(s.selectableProviders.isEmpty)
            } header: {
                Text("General")
            }

            Section {
                SecureField("Cerebras API Key", text: $s.cerebrasAPIKey)
                    .textFieldStyle(.roundedBorder)
                SecureField("OpenAI API Key", text: $s.openaiAPIKey)
                    .textFieldStyle(.roundedBorder)
                SecureField("Anthropic API Key", text: $s.anthropicAPIKey)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("API Keys")
            }

            Section {
                HStack(spacing: 6) {
                    if settings.hasRequiredAPIKey {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Ready to humanize")
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Add at least one API key")
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 380)
    }
}
#endif
