import SwiftUI
import HumanizeShared

struct HumanizeView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var viewModel: HumanizeViewModel

    init(viewModel: HumanizeViewModel = HumanizeViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MobileTheme.bg1, MobileTheme.bg2, MobileTheme.bg3],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerView

                    if !settings.hasRequiredAPIKey {
                        setupView
                    } else {
                        mainView
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showSettings) {
            MobileSettingsView()
        }
        .sheet(isPresented: $viewModel.showAnalysis) {
            AnalysisSheetView(analysis: viewModel.analysisText ?? "")
        }
        .alert("Something went wrong", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
            Button("Open Settings") { viewModel.showSettings = true }
        } message: {
            Text(viewModel.errorAlertMessage)
        }
        .sensoryFeedback(.success, trigger: viewModel.outputVisible) { old, new in
            !old && new
        }
        .preferredColorScheme(settings.appearance.colorScheme)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(MobileTheme.sky100)
                    .frame(width: 32, height: 32)
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MobileTheme.sky700)
            }

            Text("Humanize")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(MobileTheme.textPrimary)

            Spacer()

            Text(settings.provider.displayName)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.3)
                .foregroundStyle(MobileTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(MobileTheme.pillBg)
                        .stroke(MobileTheme.pillBorder, lineWidth: 1)
                )

            Button {
                viewModel.showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 15))
                    .foregroundStyle(MobileTheme.textTertiary)
            }
        }
    }

    // MARK: - Setup

    private var setupView: some View {
        VStack(spacing: 14) {
            Spacer()
                .frame(height: 40)

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(MobileTheme.sky500.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: "key.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(MobileTheme.sky600)
                }

                Text("API Key Required")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(MobileTheme.textPrimary)

                Text("Add at least one API key to get started. Cerebras is recommended by default.")
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MobileTheme.textSecondary)
                    .lineSpacing(2)

                Button {
                    viewModel.showSettings = true
                } label: {
                    Text("Open Settings")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(MobileTheme.sky600)
                        )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(MobileTheme.cardBg)
                    .stroke(MobileTheme.cardBorder, lineWidth: 1)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(MobileTheme.cardRing, lineWidth: 1)
            )

            Spacer()
                .frame(height: 40)
        }
    }

    // MARK: - Main view

    @ViewBuilder
    private var mainView: some View {
        // Input card
        TextEditor(text: $viewModel.inputText)
            .font(.system(size: 15))
            .lineSpacing(2)
            .frame(minHeight: 120, maxHeight: 280)
            .padding(12)
            .overlay(alignment: .topLeading) {
                if viewModel.inputText.isEmpty {
                    Text("Paste text here...")
                        .font(.system(size: 15))
                        .foregroundStyle(MobileTheme.textTertiary)
                        .padding(16)
                        .allowsHitTesting(false)
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(MobileTheme.cardBg)
                    .stroke(MobileTheme.cardBorder, lineWidth: 1)
                    .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(MobileTheme.cardRing, lineWidth: 1)
            )
            .onChange(of: viewModel.inputText) {
                viewModel.normalizeInput()
            }

        // Tone pills
        tonePillsRow

        // Action button
        actionButton

        // Shimmer loading
        if viewModel.isProcessing && !viewModel.hasOutput {
            PulseLoadingView()
        }

        // Output card with fade-in
        if viewModel.hasOutput {
            TextEditor(text: .constant(viewModel.outputText))
                .font(.system(size: 15))
                .lineSpacing(2)
                .frame(minHeight: 120)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(MobileTheme.cardBg)
                        .stroke(MobileTheme.sky600.opacity(0.25), lineWidth: 1)
                        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .opacity(viewModel.outputVisible ? 1 : 0)
                .offset(y: viewModel.outputVisible ? 0 : 8)
                .animation(.easeOut(duration: 0.35), value: viewModel.outputVisible)

            actionButtonsRow
                .opacity(viewModel.outputVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.35), value: viewModel.outputVisible)
        }

        // Status badge
        if viewModel.hasStatus {
            statusBadge
        }
    }

    // MARK: - Tone Pills

    private var tonePillsRow: some View {
        @Bindable var s = settings
        return HStack(spacing: 6) {
            ForEach(HumanizeTone.allCases, id: \.self) { tone in
                Button {
                    s.tone = tone
                } label: {
                    Text(tone.rawValue.capitalized)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(s.tone == tone ? .white : MobileTheme.toneInactive)
                        .padding(.vertical, 8)
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
    }

    // MARK: - Action Button

    private var actionButton: some View {
        let isEmpty = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return Button {
            if isEmpty {
                viewModel.pasteAndHumanize(settings: settings)
            } else {
                viewModel.humanize(settings: settings)
            }
        } label: {
            Group {
                if viewModel.isProcessing {
                    ProgressView()
                        .tint(MobileTheme.sky700)
                } else {
                    HStack(spacing: 8) {
                        if isEmpty {
                            Image(systemName: "doc.on.clipboard.fill")
                                .font(.system(size: 14))
                        }
                        Text(isEmpty ? "Paste & Humanize" : "Humanize")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
            .foregroundStyle(MobileTheme.sky700)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(MobileTheme.sky100)
                    .stroke(MobileTheme.sky200, lineWidth: 1)
            )
        }
        .disabled(viewModel.isProcessing)
    }

    // MARK: - Action Buttons

    private var actionButtonsRow: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.copyOutput()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MobileTheme.sky700)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(MobileTheme.sky100)
                            .stroke(MobileTheme.sky200, lineWidth: 1)
                    )
            }

            if viewModel.hasAnalysis {
                Button {
                    viewModel.showAnalysis = true
                } label: {
                    Label("Details", systemImage: "text.magnifyingglass")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MobileTheme.sky700)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(MobileTheme.sky100)
                                .stroke(MobileTheme.sky200, lineWidth: 1)
                        )
                }
            }

            Button {
                viewModel.clear()
            } label: {
                Label("Clear", systemImage: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MobileTheme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(MobileTheme.pillBg)
                            .stroke(MobileTheme.pillBorder, lineWidth: 1)
                    )
            }

            Spacer()
        }
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: viewModel.statusKind == .error ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(viewModel.statusKind == .error ? .red : .green)
            Text(viewModel.statusMessage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(viewModel.statusKind == .error ? .red.opacity(0.85) : MobileTheme.textSecondary)
                .lineLimit(2)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(viewModel.statusKind == .error ? Color.red.opacity(0.08) : MobileTheme.pillBg)
                .stroke(viewModel.statusKind == .error ? Color.red.opacity(0.22) : MobileTheme.pillBorder, lineWidth: 1)
        )
    }
}

// MARK: - Analysis Sheet

private struct AnalysisSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let analysis: String

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(analysis)
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .foregroundStyle(MobileTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .background(MobileTheme.bg1)
            .navigationTitle("AI Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Pulse Loading View

private struct PulseLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 6)
                    .fill(MobileTheme.sky200.opacity(0.5))
                    .frame(height: 14)
                    .frame(maxWidth: index == 2 ? 200 : .infinity)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(isAnimating ? 0.4 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.9)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: isAnimating
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(MobileTheme.cardBg)
                .stroke(MobileTheme.cardBorder, lineWidth: 1)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
        )
        .onAppear {
            isAnimating = true
        }
    }
}
