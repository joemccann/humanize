import Foundation
import SwiftUI
import HumanizeShared

@Observable
@MainActor
final class HumanizeViewModel {
    enum StatusKind: Sendable {
        case success
        case error
    }

    // MARK: - State

    var inputText = ""
    var outputText = ""
    var analysisText: String?
    var showAnalysis = false
    var statusMessage = ""
    var statusKind: StatusKind = .success
    var isProcessing = false
    var showSettings = false
    var outputVisible = false
    var showErrorAlert = false
    var errorAlertMessage = ""

    // MARK: - Computed

    var isDisabled: Bool {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing
    }

    var hasOutput: Bool { !outputText.isEmpty }
    var hasAnalysis: Bool { analysisText != nil }
    var hasStatus: Bool { !statusMessage.isEmpty }

    // MARK: - Dependencies

    private let service: HumanizeAPIService

    init(service: HumanizeAPIService = HumanizeAPIService()) {
        self.service = service
    }

    // MARK: - Actions

    func humanize(settings: SettingsStore) {
        guard settings.hasRequiredAPIKey else {
            setErrorStatus("Add at least one API key in Settings.")
            showErrorAlert = true
            errorAlertMessage = "Add at least one API key in Settings."
            return
        }

        let input = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let attemptOrder = settings.providerAttemptOrder

        isProcessing = true
        clearStatus()
        outputText = ""
        outputVisible = false

        Task {
            var lastError: Error?

            do {
                for provider in attemptOrder {
                    guard let apiKey = settings.apiKey(for: provider) else { continue }

                    do {
                        let result = try await service.humanize(
                            text: input,
                            tone: settings.tone,
                            provider: provider,
                            apiKey: apiKey
                        )

                        outputText = result.text
                        analysisText = result.analysis
                        MobileClipboard.copy(result.text)

                        let isFallback = result.provider != settings.provider || result.model != result.provider.defaultModel
                        let providerLabel = isFallback
                            ? "\(result.provider.displayName) (\(result.model))"
                            : result.provider.displayName
                        setSuccessStatus("Done via \(providerLabel) in \(formatLatencySeconds(result.latencyMs)) — copied to clipboard")

                        withAnimation(.easeOut(duration: 0.35)) {
                            outputVisible = true
                        }

                        isProcessing = false
                        return
                    } catch {
                        lastError = error
                    }
                }

                if let lastError {
                    let message = errorMessage(for: lastError)
                    setErrorStatus(message)
                    if isCriticalError(lastError) {
                        errorAlertMessage = message
                        showErrorAlert = true
                    }
                } else {
                    setErrorStatus("Add at least one API key in Settings.")
                }
            }
            isProcessing = false
        }
    }

    func pasteAndHumanize(settings: SettingsStore) {
        guard let pasted = MobileClipboard.currentString,
              !pasted.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            setErrorStatus("Nothing on the clipboard to paste.")
            return
        }
        inputText = pasted
        humanize(settings: settings)
    }

    func copyOutput() {
        MobileClipboard.copy(outputText)
        setSuccessStatus("Copied to clipboard")
    }

    func clear() {
        inputText = ""
        outputText = ""
        analysisText = nil
        showAnalysis = false
        outputVisible = false
        clearStatus()
    }

    func normalizeInput() {
        let cleaned = normalizeInputWhitespace(inputText)
        if cleaned != inputText {
            inputText = cleaned
        }
    }

    // MARK: - Error mapping

    func userFacingErrorMessage(for error: HumanizeError) -> String {
        switch error {
        case .noAPIKey:
            return "Add at least one API key in Settings."
        case .invalidResponse:
            return "The service returned an unreadable response. Please try again."
        case .networkError:
            return "Couldn't connect to the provider. Check your internet connection and try again."
        case .apiError(_, let message):
            return message
        }
    }

    // MARK: - Private

    private func errorMessage(for error: Error) -> String {
        if let humanizeError = error as? HumanizeError {
            return userFacingErrorMessage(for: humanizeError)
        }
        return "Something went wrong. Please try again."
    }

    private func isCriticalError(_ error: Error) -> Bool {
        guard let humanizeError = error as? HumanizeError else { return false }
        switch humanizeError {
        case .networkError, .noAPIKey:
            return true
        case .invalidResponse, .apiError:
            return false
        }
    }

    private func setSuccessStatus(_ message: String) {
        statusKind = .success
        statusMessage = message
    }

    private func setErrorStatus(_ message: String) {
        statusKind = .error
        statusMessage = message
    }

    private func clearStatus() {
        statusKind = .success
        statusMessage = ""
    }
}
