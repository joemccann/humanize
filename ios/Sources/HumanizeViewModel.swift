import Foundation
import SwiftUI
import HumanizeShared

@Observable
@MainActor
final class HumanizeViewModel {
    // MARK: - State

    var inputText = ""
    var showAnalysis = false
    var showSettings = false
    var showErrorAlert = false
    var errorAlertMessage = ""

    // MARK: - Controller

    let controller: HumanizeController

    // MARK: - Computed (delegating to controller)

    var outputText: String { controller.outputText }
    var analysisText: String? { controller.analysisText }
    var statusMessage: String { controller.statusMessage }
    var statusKind: StatusKind { controller.statusKind }
    var isProcessing: Bool { controller.isProcessing }
    var outputVisible: Bool { controller.outputVisible }
    var isDisabled: Bool {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing
    }
    var hasOutput: Bool { controller.hasOutput }
    var hasAnalysis: Bool { controller.hasAnalysis }
    var hasStatus: Bool { controller.hasStatus }

    // MARK: - Init

    init(service: HumanizeAPIService = HumanizeAPIService()) {
        self.controller = HumanizeController(
            service: service,
            onCopyToClipboard: { text in
                MobileClipboard.copy(text)
            }
        )
    }

    // Testable init with explicit controller
    init(controller: HumanizeController) {
        self.controller = controller
    }

    // MARK: - Actions

    func humanize(settings: SettingsStore) {
        guard settings.hasRequiredAPIKey else {
            controller.setErrorStatus(HumanizeError.noAPIKey.userFacingDescription)
            showErrorAlert = true
            errorAlertMessage = HumanizeError.noAPIKey.userFacingDescription
            return
        }

        controller.humanize(input: inputText, settings: settings)
    }

    func pasteAndHumanize(settings: SettingsStore) {
        guard let pasted = MobileClipboard.currentString,
              !pasted.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            controller.setErrorStatus("Nothing on the clipboard to paste.")
            return
        }
        inputText = pasted
        humanize(settings: settings)
    }

    func copyOutput() {
        controller.copyOutput()
    }

    func clear() {
        inputText = ""
        showAnalysis = false
        controller.clear()
    }

    func normalizeInput() {
        let cleaned = normalizeInputWhitespace(inputText)
        if cleaned != inputText {
            inputText = cleaned
        }
    }
}
