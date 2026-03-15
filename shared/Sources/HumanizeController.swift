import Foundation

/// Status kind for user-facing status messages.
public enum StatusKind: Sendable {
    case success
    case error
}

/// Shared controller that owns the humanize orchestration flow.
///
/// Both macOS and iOS views delegate to this controller instead of duplicating
/// the provider-attempt loop, result formatting, and status management.
@Observable
@MainActor
public final class HumanizeController {
    // MARK: - State

    public var outputText = ""
    public var analysisText: String?
    public var statusMessage = ""
    public var statusKind: StatusKind = .success
    public var isProcessing = false
    public var outputVisible = false
    public private(set) var currentTask: Task<Void, Never>?

    // MARK: - Computed

    public var hasOutput: Bool { !outputText.isEmpty }
    public var hasAnalysis: Bool { analysisText != nil }
    public var hasStatus: Bool { !statusMessage.isEmpty }

    // MARK: - Dependencies

    private let service: HumanizeAPIService
    private let onCopyToClipboard: @MainActor (String) -> Void

    public init(
        service: HumanizeAPIService = HumanizeAPIService(),
        onCopyToClipboard: @escaping @MainActor (String) -> Void
    ) {
        self.service = service
        self.onCopyToClipboard = onCopyToClipboard
    }

    // MARK: - Actions

    /// Humanize the given input text using the settings store's provider/tone.
    public func humanize(input: String, settings: SettingsStore) {
        guard settings.hasRequiredAPIKey else {
            setErrorStatus(HumanizeError.noAPIKey.userFacingDescription)
            return
        }

        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let attemptOrder = settings.providerAttemptOrder

        cancelCurrentTask()
        isProcessing = true
        clearStatus()
        outputText = ""
        outputVisible = false

        currentTask = Task {
            var lastError: Error?

            for provider in attemptOrder {
                if Task.isCancelled { break }
                guard let apiKey = settings.apiKey(for: provider) else { continue }

                do {
                    let result = try await service.humanize(
                        text: text,
                        tone: settings.tone,
                        provider: provider,
                        apiKey: apiKey
                    )

                    guard !Task.isCancelled else { return }

                    outputText = result.text
                    analysisText = result.analysis
                    onCopyToClipboard(result.text)

                    let isFallback = result.provider != settings.provider || result.model != result.provider.defaultModel
                    let providerLabel = isFallback
                        ? "\(result.provider.displayName) (\(result.model))"
                        : result.provider.displayName
                    setSuccessStatus("Done via \(providerLabel) in \(formatLatencySeconds(result.latencyMs)) — copied to clipboard")

                    outputVisible = true
                    isProcessing = false
                    return
                } catch {
                    lastError = error
                }
            }

            guard !Task.isCancelled else { return }

            if let lastError {
                let message = (lastError as? HumanizeError)?.userFacingDescription
                    ?? "Something went wrong. Please try again."
                setErrorStatus(message)
            } else {
                setErrorStatus(HumanizeError.noAPIKey.userFacingDescription)
            }
            isProcessing = false
        }
    }

    /// Copy the current output to clipboard and show status.
    public func copyOutput() {
        onCopyToClipboard(outputText)
        setSuccessStatus("Copied to clipboard")
    }

    /// Reset all state. Cancels any in-flight request.
    public func clear() {
        cancelCurrentTask()
        outputText = ""
        analysisText = nil
        outputVisible = false
        clearStatus()
        isProcessing = false
    }

    /// Cancel the current in-flight humanize request.
    public func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }

    // MARK: - Status helpers

    public func setSuccessStatus(_ message: String) {
        statusKind = .success
        statusMessage = message
    }

    public func setErrorStatus(_ message: String) {
        statusKind = .error
        statusMessage = message
    }

    public func clearStatus() {
        statusKind = .success
        statusMessage = ""
    }

    /// The last error if the status is currently showing an error, as a HumanizeError.
    public var lastHumanizeError: HumanizeError? {
        guard statusKind == .error else { return nil }
        if statusMessage.contains("API key") { return .noAPIKey }
        if statusMessage.contains("connect") { return .networkError("") }
        return nil
    }
}
