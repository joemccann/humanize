#if os(macOS)
import SwiftUI
import AppKit
import HumanizeShared

/// The SwiftUI view hosted inside the floating panel.
/// Provides a single-line text field — press Enter to humanize, Escape to dismiss.
struct LauncherInputView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var inputText = ""
    @State private var isProcessing = false
    @State private var statusMessage = ""

    let onSubmit: (String) async -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.7))

                if isProcessing {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    TextField("Paste text and press Enter to humanize...", text: $inputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .onSubmit {
                            submit()
                        }
                }

                if !statusMessage.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 14))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .onExitCommand {
            onDismiss()
        }
    }

    private func submit() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isProcessing else { return }

        isProcessing = true
        statusMessage = ""

        Task {
            await onSubmit(text)
            isProcessing = false
            inputText = ""
            statusMessage = "Copied!"

            // Auto-dismiss after a brief delay
            try? await Task.sleep(for: .milliseconds(600))
            statusMessage = ""
        }
    }
}
#endif
