import Testing
import Foundation
@testable import HumanizeMobile
import HumanizeShared
import HumanizeTestSupport

@MainActor
@Suite("HumanizeViewModel")
struct HumanizeViewModelTests {
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
        MockHTTPClient { _ in
            mockResponse(json: [
                "choices": [["message": ["content": text]]]
            ])
        }
    }

    private func errorClient(statusCode: Int = 500, message: String = "Server error") -> MockHTTPClient {
        MockHTTPClient { _ in
            mockResponse(json: ["error": ["message": message]], statusCode: statusCode)
        }
    }

    // MARK: - Initial state

    @Test("Initial state is empty and disabled")
    func initialState() {
        let vm = HumanizeViewModel()
        #expect(vm.inputText.isEmpty)
        #expect(vm.outputText.isEmpty)
        #expect(vm.analysisText == nil)
        #expect(vm.showAnalysis == false)
        #expect(vm.statusMessage.isEmpty)
        #expect(vm.isProcessing == false)
        #expect(vm.outputVisible == false)
        #expect(vm.showErrorAlert == false)
        #expect(vm.isDisabled == true)
        #expect(vm.hasOutput == false)
        #expect(vm.hasAnalysis == false)
        #expect(vm.hasStatus == false)
    }

    // MARK: - isDisabled

    @Test("isDisabled is true for whitespace-only input")
    func disabledWhitespace() {
        let vm = HumanizeViewModel()
        vm.inputText = "   \n  "
        #expect(vm.isDisabled == true)
    }

    @Test("isDisabled is false when input has content")
    func enabledWithContent() {
        let vm = HumanizeViewModel()
        vm.inputText = "Hello world"
        #expect(vm.isDisabled == false)
    }

    @Test("isDisabled is true while processing")
    func disabledWhileProcessing() {
        let vm = HumanizeViewModel()
        vm.inputText = "Hello"
        vm.isProcessing = true
        #expect(vm.isDisabled == true)
    }

    // MARK: - humanize

    @Test("humanize success sets output and outputVisible")
    func humanizeSuccess() async throws {
        let client = successClient(text: "Clean text")
        let vm = HumanizeViewModel(service: HumanizeAPIService(httpClient: client))
        let settings = makeSettings(cerebrasKey: "cbr-test")

        vm.inputText = "AI-sounding text"
        vm.humanize(settings: settings)

        // Wait for async Task to complete
        try await Task.sleep(for: .milliseconds(100))

        #expect(vm.outputText == "Clean text")
        #expect(vm.outputVisible == true)
        #expect(vm.isProcessing == false)
        #expect(vm.statusKind == .success)
        #expect(vm.statusMessage.contains("Done via"))
    }

    @Test("humanize error sets error status")
    func humanizeError() async throws {
        let client = errorClient()
        let vm = HumanizeViewModel(service: HumanizeAPIService(httpClient: client))
        let settings = makeSettings(cerebrasKey: "cbr-test")

        vm.inputText = "Some text"
        vm.humanize(settings: settings)

        try await Task.sleep(for: .milliseconds(100))

        #expect(vm.outputText.isEmpty)
        #expect(vm.outputVisible == false)
        #expect(vm.isProcessing == false)
        #expect(vm.statusKind == .error)
        #expect(!vm.statusMessage.isEmpty)
    }

    @Test("humanize with no API key shows immediate error")
    func humanizeNoKey() {
        let vm = HumanizeViewModel()
        let settings = makeSettings()

        vm.inputText = "Some text"
        vm.humanize(settings: settings)

        #expect(vm.isProcessing == false)
        #expect(vm.statusKind == .error)
        #expect(vm.statusMessage.contains("API key"))
        #expect(vm.showErrorAlert == true)
    }

    @Test("humanize with network error sets critical alert")
    func humanizeNetworkError() async throws {
        let client = MockHTTPClient { _ in
            throw HumanizeError.networkError("No connection")
        }
        let vm = HumanizeViewModel(service: HumanizeAPIService(httpClient: client))
        let settings = makeSettings(cerebrasKey: "cbr-test")

        vm.inputText = "Some text"
        vm.humanize(settings: settings)

        try await Task.sleep(for: .milliseconds(100))

        #expect(vm.statusKind == .error)
        #expect(vm.showErrorAlert == true)
        #expect(vm.errorAlertMessage.contains("connect"))
    }

    // MARK: - clear

    @Test("humanize with structured response sets analysisText")
    func humanizeWithAnalysis() async throws {
        let client = successClient(text: "Clean text.\n---\nToo many em-dashes.")
        let vm = HumanizeViewModel(service: HumanizeAPIService(httpClient: client))
        let settings = makeSettings(cerebrasKey: "cbr-test")

        vm.inputText = "AI-sounding text"
        vm.humanize(settings: settings)

        try await Task.sleep(for: .milliseconds(100))

        #expect(vm.outputText == "Clean text.")
        #expect(vm.analysisText == "Too many em-dashes.")
        #expect(vm.hasAnalysis == true)
    }

    @Test("humanize with plain response has nil analysisText")
    func humanizeWithoutAnalysis() async throws {
        let client = successClient(text: "Just clean text.")
        let vm = HumanizeViewModel(service: HumanizeAPIService(httpClient: client))
        let settings = makeSettings(cerebrasKey: "cbr-test")

        vm.inputText = "Input text"
        vm.humanize(settings: settings)

        try await Task.sleep(for: .milliseconds(100))

        #expect(vm.outputText == "Just clean text.")
        #expect(vm.analysisText == nil)
        #expect(vm.hasAnalysis == false)
    }

    // MARK: - clear

    @Test("clear resets all state including analysis")
    func clearResetsState() {
        let vm = HumanizeViewModel()
        vm.inputText = "text"
        vm.outputText = "result"
        vm.analysisText = "some analysis"
        vm.showAnalysis = true
        vm.outputVisible = true
        vm.statusMessage = "Done"

        vm.clear()

        #expect(vm.inputText.isEmpty)
        #expect(vm.outputText.isEmpty)
        #expect(vm.analysisText == nil)
        #expect(vm.showAnalysis == false)
        #expect(vm.outputVisible == false)
        #expect(vm.statusMessage.isEmpty)
    }

    // MARK: - copyOutput

    @Test("copyOutput sets success status")
    func copyOutputStatus() {
        let vm = HumanizeViewModel()
        vm.outputText = "result text"

        vm.copyOutput()

        #expect(vm.statusKind == .success)
        #expect(vm.statusMessage == "Copied to clipboard")
    }

    // MARK: - userFacingErrorMessage

    @Test("userFacingErrorMessage maps noAPIKey")
    func errorMessageNoKey() {
        let vm = HumanizeViewModel()
        let msg = vm.userFacingErrorMessage(for: .noAPIKey)
        #expect(msg.contains("API key"))
    }

    @Test("userFacingErrorMessage maps invalidResponse")
    func errorMessageInvalidResponse() {
        let vm = HumanizeViewModel()
        let msg = vm.userFacingErrorMessage(for: .invalidResponse)
        #expect(msg.contains("unreadable"))
    }

    @Test("userFacingErrorMessage maps networkError")
    func errorMessageNetwork() {
        let vm = HumanizeViewModel()
        let msg = vm.userFacingErrorMessage(for: .networkError("timeout"))
        #expect(msg.contains("connect"))
    }

    @Test("userFacingErrorMessage maps apiError")
    func errorMessageAPI() {
        let vm = HumanizeViewModel()
        let msg = vm.userFacingErrorMessage(for: .apiError(status: 429, message: "Rate limited"))
        #expect(msg == "Rate limited")
    }

    // MARK: - normalizeInput

    @Test("normalizeInput cleans whitespace")
    func normalizeInputCleansWhitespace() {
        let vm = HumanizeViewModel()
        vm.inputText = "hello   world\r\nfoo"

        vm.normalizeInput()

        #expect(vm.inputText == "hello world\nfoo")
    }

    @Test("normalizeInput is no-op for clean text")
    func normalizeInputNoOp() {
        let vm = HumanizeViewModel()
        vm.inputText = "clean text"

        vm.normalizeInput()

        #expect(vm.inputText == "clean text")
    }
}
