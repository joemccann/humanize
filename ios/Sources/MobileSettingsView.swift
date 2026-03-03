import SwiftUI
import HumanizeShared

struct MobileSettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var showCerebrasKey = false
    @State private var showOpenAIKey = false
    @State private var showAnthropicKey = false

    var body: some View {
        NavigationStack {
            settingsForm
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(MobileTheme.textTertiary)
                        }
                    }
                }
        }
        .preferredColorScheme(settings.appearance.colorScheme)
    }

    // MARK: - Form

    private var settingsForm: some View {
        @Bindable var s = settings
        return Form {
            // Appearance
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        ForEach(AppAppearance.allCases, id: \.self) { mode in
                            Button {
                                s.appearance = mode
                            } label: {
                                Text(mode.rawValue.capitalized)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(s.appearance == mode ? .white : MobileTheme.toneInactive)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(s.appearance == mode ? MobileTheme.sky600 : MobileTheme.pillBg)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(s.appearance == mode ? .clear : MobileTheme.pillBorder, lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            } header: {
                sectionHeader("Appearance")
            }

            // Provider
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        ForEach(AIProvider.allCases, id: \.self) { provider in
                            let isSelectable = s.hasAPIKey(for: provider)
                            Button {
                                guard isSelectable else { return }
                                s.provider = provider
                            } label: {
                                Text(provider.displayName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(s.provider == provider ? .white : MobileTheme.toneInactive)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(s.provider == provider ? MobileTheme.sky600 : MobileTheme.pillBg)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(s.provider == provider ? .clear : MobileTheme.pillBorder, lineWidth: 1)
                                    )
                            }
                            .disabled(!isSelectable)
                            .opacity(isSelectable ? 1 : 0.45)
                        }
                    }

                    if s.selectableProviders.isEmpty {
                        Text("Add an API key to enable provider selection.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(MobileTheme.textTertiary)
                    }
                }
            } header: {
                sectionHeader("Provider")
            }

            // Default Tone
            Section {
                HStack(spacing: 4) {
                    ForEach(HumanizeTone.allCases, id: \.self) { tone in
                        Button {
                            s.tone = tone
                        } label: {
                            Text(tone.rawValue.capitalized)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(s.tone == tone ? .white : MobileTheme.toneInactive)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(s.tone == tone ? MobileTheme.sky600 : MobileTheme.pillBg)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(s.tone == tone ? .clear : MobileTheme.pillBorder, lineWidth: 1)
                                )
                        }
                    }
                }
            } header: {
                sectionHeader("Default Tone")
            }

            // API Keys
            Section {
                apiKeyRow(
                    label: "Cerebras",
                    placeholder: "Paste Cerebras API key",
                    value: $s.cerebrasAPIKey,
                    isRevealed: $showCerebrasKey
                )

                apiKeyRow(
                    label: "OpenAI",
                    placeholder: "sk-...",
                    value: $s.openaiAPIKey,
                    isRevealed: $showOpenAIKey
                )

                apiKeyRow(
                    label: "Anthropic",
                    placeholder: "sk-ant-...",
                    value: $s.anthropicAPIKey,
                    isRevealed: $showAnthropicKey
                )
            } header: {
                sectionHeader("API Keys")
            }

            // Status
            Section {
                HStack(spacing: 8) {
                    if settings.hasRequiredAPIKey {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 14))
                        Text("Ready to humanize")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(MobileTheme.textSecondary)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 14))
                        Text("Add at least one API key (Cerebras recommended)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(MobileTheme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .textCase(.uppercase)
            .tracking(0.8)
    }

    private func apiKeyRow(
        label: String,
        placeholder: String,
        value: Binding<String>,
        isRevealed: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MobileTheme.textPrimary)

            HStack(spacing: 8) {
                Group {
                    if isRevealed.wrappedValue {
                        TextField(placeholder, text: value)
                            .font(.system(size: 14, design: .monospaced))
                    } else {
                        SecureField(placeholder, text: value)
                            .font(.system(size: 14))
                    }
                }
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                Button {
                    isRevealed.wrappedValue.toggle()
                } label: {
                    Image(systemName: isRevealed.wrappedValue ? "eye.slash" : "eye")
                        .font(.system(size: 13))
                        .foregroundStyle(MobileTheme.textTertiary)
                }

                Circle()
                    .fill(value.wrappedValue.isEmpty ? Color.red.opacity(0.6) : Color.green.opacity(0.7))
                    .frame(width: 10, height: 10)
            }
        }
    }
}
