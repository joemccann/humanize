import SwiftUI

struct PopoverView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var statusMessage = ""
    @State private var isProcessing = false

    private let service = HumanizeAPIService()

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Humanize")
                    .font(.headline)
                Spacer()
                SettingsLink {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
            }

            if !settings.hasRequiredAPIKey {
                setupView
            } else {
                mainView
            }
        }
        .padding()
        .frame(minWidth: 400, maxWidth: 400, minHeight: 300)
    }

    private var setupView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "key.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("API Key Required")
                .font(.title3.bold())
            Text("Add your \(settings.provider.displayName) API key in Settings to get started.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            SettingsLink {
                Text("Open Settings")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }

    @ViewBuilder
    private var mainView: some View {
            // Input
            TextEditor(text: $inputText)
                .font(.body)
                .frame(minHeight: 120)
                .overlay(alignment: .topLeading) {
                    if inputText.isEmpty {
                        Text("Paste text here...")
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 5)
                            .padding(.top, 2)
                            .allowsHitTesting(false)
                    }
                }
                .contentMargins(.all, 4, for: .scrollContent)
                .scrollContentBackground(.hidden)
                .background(Color(.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onChange(of: inputText) { _, newValue in
                    let cleaned = normalizeWhitespace(newValue)
                    if cleaned != newValue {
                        inputText = cleaned
                    }
                }

            // Tone picker
            @Bindable var s = settings
            Picker("Tone", selection: $s.tone) {
                ForEach(HumanizeTone.allCases, id: \.self) { tone in
                    Text(tone.rawValue.capitalized).tag(tone)
                }
            }
            .pickerStyle(.segmented)

            // Humanize button
            Button(action: humanize) {
                if isProcessing {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Humanize")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
            .keyboardShortcut(.return, modifiers: .command)

            // Output
            if !outputText.isEmpty {
                TextEditor(text: .constant(outputText))
                    .font(.body)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .background(Color(.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                HStack {
                    Button("Copy to Clipboard") {
                        copyToClipboard(outputText)
                        statusMessage = "Copied to clipboard"
                    }
                    .buttonStyle(.bordered)

                    Button("Clear") {
                        inputText = ""
                        outputText = ""
                        statusMessage = ""
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Status
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(statusMessage.contains("Error") ? .red : .secondary)
            }
    }

    private func humanize() {
        guard settings.hasRequiredAPIKey, let apiKey = settings.currentAPIKey else {
            statusMessage = "Error: No API key. Open Settings to add one."
            return
        }

        isProcessing = true
        statusMessage = ""
        outputText = ""

        Task {
            do {
                let result = try await service.humanize(
                    text: inputText.trimmingCharacters(in: .whitespacesAndNewlines),
                    tone: settings.tone,
                    provider: settings.provider,
                    apiKey: apiKey
                )
                outputText = result.text
                copyToClipboard(result.text)
                statusMessage = "Done in \(result.latencyMs)ms — copied to clipboard"
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
            }
            isProcessing = false
        }
    }

    private func normalizeWhitespace(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "[\\t ]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: " *\n *", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
