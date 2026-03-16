import Testing
import Foundation
@testable import HumanizeShared
import HumanizeTestSupport

@MainActor
@Suite("HumanizeController", .serialized)
struct HumanizeControllerTests {
    private func freshDefaults() -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func makeSettings(cerebrasKey: String? = nil) -> SettingsStore {
        let store = SettingsStore(defaults: freshDefaults())
        if let key = cerebrasKey {
            store.cerebrasAPIKey = key
        }
        return store
    }

    private func successClient(text: String = "Humanized output") -> MockHTTPClient {
        MockHTTPClient { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("/models") {
                return mockResponse(json: ["data": []])
            }
            return mockResponse(json: [
                "choices": [["message": ["content": text]]]
            ])
        }
    }

    private func delayedClient(delayMs: Int = 500, text: String = "Delayed") -> MockHTTPClient {
        MockHTTPClient { _ in
            try await Task.sleep(for: .milliseconds(delayMs))
            return mockResponse(json: [
                "choices": [["message": ["content": text]]]
            ])
        }
    }

    /// Poll until a condition becomes true or timeout.
    private func waitUntil(timeout: Duration = .seconds(3), condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while !condition() {
            guard ContinuousClock.now < deadline else { break }
            try await Task.sleep(for: .milliseconds(20))
        }
    }

    // MARK: - Initial state

    @Test("Initial state is clean")
    func initialState() {
        let ctrl = HumanizeController(onCopyToClipboard: { _ in })
        #expect(ctrl.outputText.isEmpty)
        #expect(ctrl.analysisText == nil)
        #expect(ctrl.statusMessage.isEmpty)
        #expect(ctrl.statusKind == .success)
        #expect(ctrl.isProcessing == false)
        #expect(ctrl.outputVisible == false)
        #expect(ctrl.hasOutput == false)
        #expect(ctrl.hasAnalysis == false)
        #expect(ctrl.hasStatus == false)
    }

    // MARK: - Humanize success

    @Test("Humanize sets output and copies to clipboard")
    func humanizeSuccess() async throws {
        let client = successClient(text: "Clean text")
        var copiedText: String?
        let ctrl = HumanizeController(
            service: HumanizeAPIService(httpClient: client),
            onCopyToClipboard: { copiedText = $0 }
        )
        let settings = makeSettings(cerebrasKey: "cbr-test")

        ctrl.humanize(input: "AI text", settings: settings)
        try await waitUntil { !ctrl.isProcessing }

        #expect(ctrl.outputText == "Clean text")
        #expect(ctrl.outputVisible == true)
        #expect(ctrl.isProcessing == false)
        #expect(ctrl.statusKind == .success)
        #expect(ctrl.statusMessage.contains("Done via"))
        #expect(copiedText == "Clean text")
    }

    // MARK: - Humanize with analysis

    @Test("Humanize with analysis sets analysisText")
    func humanizeWithAnalysis() async throws {
        let client = successClient(text: "Clean.\n---\nFixed em-dashes.")
        let ctrl = HumanizeController(
            service: HumanizeAPIService(httpClient: client),
            onCopyToClipboard: { _ in }
        )
        let settings = makeSettings(cerebrasKey: "cbr-test")

        ctrl.humanize(input: "Input", settings: settings)
        try await waitUntil { !ctrl.isProcessing }

        #expect(ctrl.outputText == "Clean.")
        #expect(ctrl.analysisText == "Fixed em-dashes.")
        #expect(ctrl.hasAnalysis == true)
    }

    // MARK: - No API key

    @Test("Humanize without API key shows immediate error")
    func humanizeNoKey() {
        let ctrl = HumanizeController(onCopyToClipboard: { _ in })
        let settings = makeSettings()

        ctrl.humanize(input: "Text", settings: settings)

        #expect(ctrl.isProcessing == false)
        #expect(ctrl.statusKind == .error)
        #expect(ctrl.statusMessage.contains("API key"))
    }

    // MARK: - Error handling

    @Test("Humanize error sets error status")
    func humanizeError() async throws {
        let client = MockHTTPClient { _ in
            mockResponse(json: ["error": ["message": "Server error"]], statusCode: 500)
        }
        let ctrl = HumanizeController(
            service: HumanizeAPIService(httpClient: client),
            onCopyToClipboard: { _ in }
        )
        let settings = makeSettings(cerebrasKey: "cbr-test")

        ctrl.humanize(input: "Text", settings: settings)
        try await waitUntil { !ctrl.isProcessing }

        #expect(ctrl.outputText.isEmpty)
        #expect(ctrl.isProcessing == false)
        #expect(ctrl.statusKind == .error)
        #expect(!ctrl.statusMessage.isEmpty)
    }

    // MARK: - Clear

    @Test("Clear resets all state and cancels task")
    func clearResetsState() async throws {
        let client = delayedClient(delayMs: 2000)
        let ctrl = HumanizeController(
            service: HumanizeAPIService(httpClient: client),
            onCopyToClipboard: { _ in }
        )
        let settings = makeSettings(cerebrasKey: "cbr-test")

        ctrl.humanize(input: "Input", settings: settings)
        try await waitUntil { ctrl.isProcessing }

        ctrl.clear()
        #expect(ctrl.outputText.isEmpty)
        #expect(ctrl.analysisText == nil)
        #expect(ctrl.outputVisible == false)
        #expect(ctrl.statusMessage.isEmpty)
        #expect(ctrl.isProcessing == false)
        #expect(ctrl.currentTask == nil)
    }

    // MARK: - Task cancellation

    @Test("Cancelling task stops in-flight request")
    func taskCancellation() async throws {
        let client = delayedClient(delayMs: 2000)
        let ctrl = HumanizeController(
            service: HumanizeAPIService(httpClient: client),
            onCopyToClipboard: { _ in }
        )
        let settings = makeSettings(cerebrasKey: "cbr-test")

        ctrl.humanize(input: "Input", settings: settings)
        try await waitUntil { ctrl.isProcessing }

        ctrl.cancelCurrentTask()
        try await Task.sleep(for: .milliseconds(500))

        #expect(ctrl.outputText.isEmpty)
    }

    // MARK: - Copy output

    @Test("copyOutput copies and sets status")
    func copyOutput() {
        var copiedText: String?
        let ctrl = HumanizeController(onCopyToClipboard: { copiedText = $0 })
        ctrl.outputText = "result"

        ctrl.copyOutput()

        #expect(copiedText == "result")
        #expect(ctrl.statusKind == .success)
        #expect(ctrl.statusMessage == "Copied to clipboard")
    }

    // MARK: - Second humanize cancels first

    @Test("Starting a new humanize cancels the previous one")
    func newHumanizeCancelsPrevious() async throws {
        let client = MockHTTPClient { _ in
            try await Task.sleep(for: .milliseconds(200))
            return mockResponse(json: [
                "choices": [["message": ["content": "Result"]]]
            ])
        }
        let ctrl = HumanizeController(
            service: HumanizeAPIService(httpClient: client),
            onCopyToClipboard: { _ in }
        )
        let settings = makeSettings(cerebrasKey: "cbr-test")

        ctrl.humanize(input: "First", settings: settings)
        ctrl.humanize(input: "Second", settings: settings)

        try await waitUntil { !ctrl.isProcessing }

        #expect(ctrl.outputText == "Result")
    }
}
