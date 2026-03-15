import Testing
import Foundation
@testable import HumanizeShared

@Suite("ClipboardProvider protocol")
struct ClipboardProtocolTests {
    @Test("Protocol can be implemented with a mock")
    @MainActor
    func mockImplementation() {
        let mock = MockClipboard()
        mock.copy("hello")
        #expect(mock.currentString == "hello")
    }

    @Test("Mock clipboard overwrites on subsequent copy")
    @MainActor
    func overwrite() {
        let mock = MockClipboard()
        mock.copy("first")
        mock.copy("second")
        #expect(mock.currentString == "second")
    }

    @Test("Mock clipboard starts empty")
    @MainActor
    func startsEmpty() {
        let mock = MockClipboard()
        #expect(mock.currentString == nil)
    }
}

@MainActor
private final class MockClipboard: ClipboardProvider, @unchecked Sendable {
    private var value: String?

    nonisolated init() {}

    func copy(_ text: String) {
        value = text
    }

    var currentString: String? { value }
}
