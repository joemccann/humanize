import SwiftUI
import AppKit

// MARK: - Adaptive design tokens

private enum Theme {
    // Adaptive colors using NSColor dynamic provider
    static let bg1 = Color(nsColor: adaptive(
        light: NSColor(red: 0.878, green: 0.949, blue: 0.996, alpha: 1),
        dark: NSColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)
    ))
    static let bg2 = Color(nsColor: adaptive(
        light: .white,
        dark: NSColor(red: 0.08, green: 0.11, blue: 0.18, alpha: 1)
    ))
    static let bg3 = Color(nsColor: adaptive(
        light: NSColor(red: 0.729, green: 0.902, blue: 0.992, alpha: 0.5),
        dark: NSColor(red: 0.07, green: 0.10, blue: 0.17, alpha: 1)
    ))
    static let cardBg = Color(nsColor: adaptive(
        light: NSColor(white: 1, alpha: 0.85),
        dark: NSColor(red: 0.12, green: 0.15, blue: 0.22, alpha: 0.7)
    ))
    static let cardBorder = Color(nsColor: adaptive(
        light: NSColor(white: 1, alpha: 0.6),
        dark: NSColor(white: 1, alpha: 0.1)
    ))
    static let cardRing = Color(nsColor: adaptive(
        light: NSColor(red: 0.055, green: 0.647, blue: 0.914, alpha: 0.1),
        dark: NSColor(white: 1, alpha: 0.08)
    ))
    static let pillBg = Color(nsColor: adaptive(
        light: NSColor(white: 1, alpha: 0.7),
        dark: NSColor(red: 0.14, green: 0.17, blue: 0.24, alpha: 0.6)
    ))
    static let pillBorder = Color(nsColor: adaptive(
        light: NSColor(white: 0.5, alpha: 0.2),
        dark: NSColor(white: 1, alpha: 0.1)
    ))
    static let textPrimary = Color(nsColor: adaptive(
        light: NSColor(red: 0.057, green: 0.09, blue: 0.165, alpha: 1),
        dark: NSColor(red: 0.91, green: 0.92, blue: 0.94, alpha: 1)
    ))
    static let textSecondary = Color(nsColor: adaptive(
        light: NSColor(red: 0.392, green: 0.455, blue: 0.545, alpha: 1),
        dark: NSColor(red: 0.58, green: 0.635, blue: 0.706, alpha: 1)
    ))
    static let textTertiary = Color(nsColor: adaptive(
        light: NSColor(red: 0.58, green: 0.635, blue: 0.706, alpha: 1),
        dark: NSColor(red: 0.45, green: 0.50, blue: 0.57, alpha: 1)
    ))
    static let sky100 = Color(nsColor: adaptive(
        light: NSColor(red: 0.878, green: 0.949, blue: 0.996, alpha: 1),
        dark: NSColor(red: 0.055, green: 0.647, blue: 0.914, alpha: 0.15)
    ))
    static let sky200 = Color(nsColor: adaptive(
        light: NSColor(red: 0.729, green: 0.902, blue: 0.992, alpha: 1),
        dark: NSColor(red: 0.055, green: 0.647, blue: 0.914, alpha: 0.2)
    ))
    static let sky500 = Color(red: 0.055, green: 0.647, blue: 0.914)
    static let sky600 = Color(nsColor: adaptive(
        light: NSColor(red: 0.008, green: 0.518, blue: 0.78, alpha: 1),
        dark: NSColor(red: 0.22, green: 0.67, blue: 0.95, alpha: 1)
    ))
    static let sky700 = Color(nsColor: adaptive(
        light: NSColor(red: 0.012, green: 0.412, blue: 0.624, alpha: 1),
        dark: NSColor(red: 0.55, green: 0.82, blue: 0.97, alpha: 1)
    ))
    static let toneInactive = Color(nsColor: adaptive(
        light: NSColor(red: 0.2, green: 0.255, blue: 0.333, alpha: 1),
        dark: NSColor(red: 0.78, green: 0.80, blue: 0.84, alpha: 1)
    ))

    private static func adaptive(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }
    }
}

// MARK: - Popover

struct PopoverView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var statusMessage = ""
    @State private var isProcessing = false
    @State private var showSettings = false

    private let service = HumanizeAPIService()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.bg1, Theme.bg2, Theme.bg3],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                headerView

                if showSettings {
                    settingsContent
                } else if !settings.hasRequiredAPIKey {
                    setupView
                } else {
                    mainView
                }
            }
            .padding(16)
        }
        .frame(minWidth: 420, maxWidth: 420, minHeight: 340)
        .preferredColorScheme(settings.appearance.resolvedColorScheme)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Theme.sky100)
                    .frame(width: 28, height: 28)
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.sky700)
            }

            Text(showSettings ? "Settings" : "Humanize")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            if !showSettings {
                Text(settings.provider.displayName)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.3)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Theme.pillBg)
                            .stroke(Theme.pillBorder, lineWidth: 1)
                    )
            }

            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showSettings.toggle()
                }
            } label: {
                Image(systemName: showSettings ? "xmark" : "gearshape")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Setup

    private var setupView: some View {
        VStack(spacing: 14) {
            Spacer()

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.sky500.opacity(0.1))
                        .frame(width: 52, height: 52)
                    Image(systemName: "key.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.sky600)
                }

                Text("API Key Required")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                Text("Add your \(settings.provider.displayName) API key in Settings to get started.")
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(2)

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showSettings = true
                    }
                } label: {
                    Text("Open Settings")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Theme.sky600)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.cardBg)
                    .stroke(Theme.cardBorder, lineWidth: 1)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.cardRing, lineWidth: 1)
            )

            Spacer()
        }
    }

    // MARK: - Inline Settings

    private var settingsContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                @Bindable var s = settings

                // Appearance
                settingsSection("Appearance") {
                    HStack(spacing: 4) {
                        ForEach(AppAppearance.allCases, id: \.self) { mode in
                            Button {
                                s.appearance = mode
                            } label: {
                                Text(mode.rawValue.capitalized)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(s.appearance == mode ? .white : Theme.toneInactive)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(s.appearance == mode ? Theme.sky600 : Theme.pillBg)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(s.appearance == mode ? .clear : Theme.pillBorder, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Provider
                settingsSection("Provider") {
                    HStack(spacing: 4) {
                        ForEach(AIProvider.allCases, id: \.self) { provider in
                            Button {
                                s.provider = provider
                            } label: {
                                Text(provider.displayName)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(s.provider == provider ? .white : Theme.toneInactive)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(s.provider == provider ? Theme.sky600 : Theme.pillBg)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(s.provider == provider ? .clear : Theme.pillBorder, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Default Tone
                settingsSection("Default Tone") {
                    HStack(spacing: 4) {
                        ForEach(HumanizeTone.allCases, id: \.self) { tone in
                            Button {
                                s.tone = tone
                            } label: {
                                Text(tone.rawValue.capitalized)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(s.tone == tone ? .white : Theme.toneInactive)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(s.tone == tone ? Theme.sky600 : Theme.pillBg)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(s.tone == tone ? .clear : Theme.pillBorder, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // API Keys
                settingsSection("OpenAI API Key") {
                    apiKeyField(
                        value: $s.openaiAPIKey,
                        placeholder: "sk-...",
                        isEmpty: s.openaiAPIKey.isEmpty
                    )
                }

                settingsSection("Anthropic API Key") {
                    apiKeyField(
                        value: $s.anthropicAPIKey,
                        placeholder: "sk-ant-...",
                        isEmpty: s.anthropicAPIKey.isEmpty
                    )
                }

                // Status
                HStack(spacing: 6) {
                    if settings.hasRequiredAPIKey {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 11))
                        Text("Ready to humanize")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 11))
                        Text("Add a \(settings.provider.displayName) API key")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.cardBg)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
    }

    private func apiKeyField(value: Binding<String>, placeholder: String, isEmpty: Bool) -> some View {
        HStack(spacing: 6) {
            SecureField(placeholder, text: value)
                .font(.system(size: 12))
                .textFieldStyle(.roundedBorder)
            Circle()
                .fill(isEmpty ? Color.red.opacity(0.6) : Color.green.opacity(0.7))
                .frame(width: 8, height: 8)
        }
    }

    // MARK: - Main view

    @ViewBuilder
    private var mainView: some View {
        // Input card
        TextEditor(text: $inputText)
            .font(.system(size: 13))
            .lineSpacing(2)
            .frame(minHeight: 110)
            .overlay {
                if inputText.isEmpty {
                    Text("Paste text here...")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textTertiary)
                        .allowsHitTesting(false)
                }
            }
            .textEditorInset(12)
            .scrollContentBackground(.hidden)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.cardBg)
                    .stroke(Theme.cardBorder, lineWidth: 1)
                    .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.cardRing, lineWidth: 1)
            )
            .onChange(of: inputText) { _, newValue in
                let cleaned = normalizeWhitespace(newValue)
                if cleaned != newValue {
                    inputText = cleaned
                }
            }

        // Tone + Humanize row
        @Bindable var s = settings
        HStack(spacing: 8) {
            // Tone pills
            HStack(spacing: 4) {
                ForEach(HumanizeTone.allCases, id: \.self) { tone in
                    Button {
                        s.tone = tone
                    } label: {
                        Text(tone.rawValue.capitalized)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(s.tone == tone ? .white : Theme.toneInactive)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(s.tone == tone ? Theme.sky600 : Theme.pillBg)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(s.tone == tone ? .clear : Theme.pillBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // Humanize button — compact, less opaque
            Button(action: humanize) {
                Group {
                    if isProcessing {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Text("Humanize")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isDisabled ? Theme.sky600.opacity(0.35) : Theme.sky600.opacity(0.85))
                )
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .keyboardShortcut(.return, modifiers: .command)
        }

        // Output card
        if !outputText.isEmpty {
            TextEditor(text: .constant(outputText))
                .font(.system(size: 13))
                .lineSpacing(2)
                .frame(minHeight: 110)
                .textEditorInset(12)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.cardBg)
                        .stroke(Theme.sky600.opacity(0.25), lineWidth: 1)
                        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 8) {
                Button {
                    copyToClipboard(outputText)
                    statusMessage = "Copied to clipboard"
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.sky700)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Theme.sky100)
                                .stroke(Theme.sky200, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    inputText = ""
                    outputText = ""
                    statusMessage = ""
                } label: {
                    Label("Clear", systemImage: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Theme.pillBg)
                                .stroke(Theme.pillBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }

        // Status badge
        if !statusMessage.isEmpty {
            HStack(spacing: 4) {
                if statusMessage.contains("Error") {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.red)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.green)
                }
                Text(statusMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(statusMessage.contains("Error") ? .red.opacity(0.8) : Theme.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Theme.pillBg)
                    .stroke(Theme.pillBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers

    private var isDisabled: Bool {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing
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
        normalizeInputWhitespace(text)
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

// MARK: - Testable helpers

func normalizeInputWhitespace(_ text: String) -> String {
    text
        .replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: "\r", with: "\n")
        .replacingOccurrences(of: "[\\t ]+", with: " ", options: .regularExpression)
        .replacingOccurrences(of: " *\n *", with: "\n", options: .regularExpression)
        .replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
}

// MARK: - NSTextView inset helper

private struct TextEditorInset: ViewModifier {
    let inset: NSSize

    func body(content: Content) -> some View {
        content
            .onAppear()
            .background(TextEditorInsetInjector(inset: inset))
    }
}

private struct TextEditorInsetInjector: NSViewRepresentable {
    let inset: NSSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { applyInset(to: view) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { applyInset(to: nsView) }
    }

    private func applyInset(to view: NSView) {
        guard let scrollView = findScrollView(in: view),
              let textView = scrollView.documentView as? NSTextView else { return }
        textView.textContainerInset = inset
    }

    private func findScrollView(in view: NSView) -> NSScrollView? {
        // Walk up the view hierarchy to find the NSScrollView that hosts the TextEditor
        var current: NSView? = view
        while let v = current {
            if let sv = v as? NSScrollView, sv.documentView is NSTextView {
                return sv
            }
            // Also check siblings (the NSScrollView is a sibling, not a parent)
            if let parent = v.superview {
                for sibling in parent.subviews where sibling !== v {
                    if let sv = sibling as? NSScrollView, sv.documentView is NSTextView {
                        return sv
                    }
                    // Check children of siblings
                    if let found = findScrollViewDown(in: sibling) {
                        return found
                    }
                }
            }
            current = v.superview
        }
        return nil
    }

    private func findScrollViewDown(in view: NSView) -> NSScrollView? {
        if let sv = view as? NSScrollView, sv.documentView is NSTextView {
            return sv
        }
        for child in view.subviews {
            if let found = findScrollViewDown(in: child) {
                return found
            }
        }
        return nil
    }
}

extension View {
    func textEditorInset(_ inset: CGFloat) -> some View {
        modifier(TextEditorInset(inset: NSSize(width: inset, height: inset)))
    }
}
