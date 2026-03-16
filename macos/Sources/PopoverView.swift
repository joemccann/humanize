import SwiftUI
#if os(macOS)
import AppKit
import HumanizeShared

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
    @State private var showAnalysis = false
    @State private var showSettings = false
    @State private var controller: HumanizeController

    let onResize: ((CGSize, Bool) -> Void)?

    init(onResize: ((CGSize, Bool) -> Void)? = nil) {
        self.onResize = onResize
        _controller = State(initialValue: HumanizeController(
            onCopyToClipboard: { text in
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
        ))
    }

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
                    mainContent
                }
            }
            .padding(16)
        }
        .overlay(alignment: .bottomTrailing) {
            if let onResize {
                PopoverResizeHandle(onResize: onResize)
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
            }
        }
        .frame(minWidth: PopoverSizing.minSize.width, minHeight: PopoverSizing.minSize.height)
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

                Text("Add at least one API key to get started. Cerebras is recommended by default.")
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
                            let isSelectable = s.hasAPIKey(for: provider)
                            Button {
                                guard isSelectable else { return }
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
                            .disabled(!isSelectable)
                            .opacity(isSelectable ? 1 : 0.45)
                        }
                    }

                    if s.selectableProviders.isEmpty {
                        Text("Add an API key to enable provider selection.")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
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
                settingsSection("Cerebras API Key") {
                    apiKeyField(
                        value: $s.cerebrasAPIKey,
                        placeholder: "Paste Cerebras API key",
                        isEmpty: s.cerebrasAPIKey.isEmpty
                    )
                }

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
                        Text("Add at least one API key (Cerebras recommended)")
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
    private var mainContent: some View {
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
                let cleaned = normalizeInputWhitespace(newValue)
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

            // Humanize button
            Button {
                controller.humanize(input: inputText, settings: settings)
            } label: {
                Group {
                    if controller.isProcessing {
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
        if controller.hasOutput {
            TextEditor(text: .constant(controller.outputText))
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
                    controller.copyOutput()
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

                if controller.hasAnalysis {
                    Button {
                        showAnalysis.toggle()
                    } label: {
                        Label("Details", systemImage: "text.magnifyingglass")
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
                    .popover(isPresented: $showAnalysis) {
                        ScrollView {
                            Text(renderedAnalysis)
                                .font(.system(size: 12))
                                .lineSpacing(3)
                                .foregroundStyle(Theme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                        }
                        .frame(width: 300, height: 200)
                    }
                }

                Button {
                    inputText = ""
                    showAnalysis = false
                    controller.clear()
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
        if controller.hasStatus {
            HStack(spacing: 6) {
                Image(systemName: controller.statusKind == .error ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(controller.statusKind == .error ? .red : .green)
                Text(controller.statusMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(controller.statusKind == .error ? .red.opacity(0.85) : Theme.textSecondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(controller.statusKind == .error ? Color.red.opacity(0.08) : Theme.pillBg)
                    .stroke(controller.statusKind == .error ? Color.red.opacity(0.22) : Theme.pillBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers

    private var isDisabled: Bool {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || controller.isProcessing
    }

    private var renderedAnalysis: AttributedString {
        guard let md = controller.analysisText else { return AttributedString() }
        let formatted = formatAnalysisForDisplay(md)
        return (try? AttributedString(markdown: formatted, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(formatted)
    }
}

private struct PopoverResizeHandle: View {
    let onResize: (CGSize, Bool) -> Void
    @State private var isHovering = false
    @State private var isDragging = false

    var body: some View {
        Color.clear
        .frame(width: 24, height: 24)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
            setCursor()
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    setCursor()
                    onResize(value.translation, false)
                }
                .onEnded { value in
                    isDragging = false
                    onResize(value.translation, true)
                    setCursor()
                }
        )
        .help("Drag to resize")
    }

    private func setCursor() {
        if isHovering || isDragging {
            NSCursor.humanizeDiagonalResize().set()
        } else {
            NSCursor.arrow.set()
        }
    }
}

private extension NSCursor {
    @MainActor static func humanizeDiagonalResize() -> NSCursor {
        let fallback = NSCursor.resizeLeftRight

        guard let symbol = NSImage(
            systemSymbolName: "arrow.up.left.and.arrow.down.right",
            accessibilityDescription: "Resize"
        ) else {
            return fallback
        }

        guard let configured = symbol.withSymbolConfiguration(
            NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        ) else {
            return fallback
        }

        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        configured.draw(
            in: NSRect(x: 2, y: 2, width: 14, height: 14),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
        image.unlockFocus()

        return NSCursor(image: image, hotSpot: NSPoint(x: 9, y: 9))
    }
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
#endif
