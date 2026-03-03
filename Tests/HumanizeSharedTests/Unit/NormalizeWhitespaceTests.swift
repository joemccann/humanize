import Testing
@testable import HumanizeShared

@Suite("normalizeInputWhitespace")
struct NormalizeWhitespaceTests {
    @Test("Passes through clean text unchanged")
    func cleanText() {
        let input = "Hello world"
        #expect(normalizeInputWhitespace(input) == "Hello world")
    }

    @Test("Converts Windows line endings to Unix")
    func windowsLineEndings() {
        #expect(normalizeInputWhitespace("a\r\nb") == "a\nb")
    }

    @Test("Converts bare carriage returns to newlines")
    func carriageReturns() {
        #expect(normalizeInputWhitespace("a\rb") == "a\nb")
    }

    @Test("Collapses multiple spaces to one")
    func multipleSpaces() {
        #expect(normalizeInputWhitespace("a   b") == "a b")
    }

    @Test("Collapses tabs to single space")
    func tabs() {
        #expect(normalizeInputWhitespace("a\t\tb") == "a b")
    }

    @Test("Strips spaces around newlines")
    func spacesAroundNewlines() {
        #expect(normalizeInputWhitespace("a  \n  b") == "a\nb")
    }

    @Test("Collapses 3+ newlines to double newline")
    func excessiveNewlines() {
        #expect(normalizeInputWhitespace("a\n\n\nb") == "a\n\nb")
        #expect(normalizeInputWhitespace("a\n\n\n\n\nb") == "a\n\nb")
    }

    @Test("Preserves double newlines (paragraph breaks)")
    func doubleNewlines() {
        #expect(normalizeInputWhitespace("a\n\nb") == "a\n\nb")
    }

    @Test("Handles empty string")
    func emptyString() {
        #expect(normalizeInputWhitespace("") == "")
    }

    @Test("Handles mixed whitespace chaos")
    func mixedWhitespace() {
        let input = "Hello  \t  world\r\n\r\n\r\nfoo   bar"
        let expected = "Hello world\n\nfoo bar"
        #expect(normalizeInputWhitespace(input) == expected)
    }

    @Test("Single newline preserved")
    func singleNewline() {
        #expect(normalizeInputWhitespace("a\nb") == "a\nb")
    }
}
