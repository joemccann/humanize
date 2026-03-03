import Testing
@testable import HumanizeMobile

@Suite("MobileClipboard")
struct ClipboardTests {
    @Test("Copy function executes without error")
    func copyDoesNotCrash() {
        MobileClipboard.copy("test clipboard")
        // UIPasteboard is not reliably available in simulator unit tests,
        // so we verify the function can be called without throwing.
    }

    @Test("currentString property is accessible")
    func currentStringAccessible() {
        // May return nil in simulator test sandbox — that's expected
        _ = MobileClipboard.currentString
    }

    @Test("Copy with empty string does not crash")
    func emptyStringDoesNotCrash() {
        MobileClipboard.copy("")
    }
}
