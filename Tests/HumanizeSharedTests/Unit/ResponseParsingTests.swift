import Testing
import Foundation
@testable import HumanizeShared

@Suite("parseHumanizeResponse")
struct ResponseParsingTests {
    // MARK: - Delimiter-based splitting

    @Test("Splits on --- delimiter into text and analysis")
    func splitOnDelimiter() {
        let raw = "Rewritten text here.\n---\nThis is the analysis section."
        let result = parseHumanizeResponse(raw)
        #expect(result.text == "Rewritten text here.")
        #expect(result.analysis == "This is the analysis section.")
    }

    @Test("Only splits on first --- delimiter")
    func splitOnFirstDelimiterOnly() {
        let raw = "Part one.\n---\nAnalysis here.\n---\nExtra section."
        let result = parseHumanizeResponse(raw)
        #expect(result.text == "Part one.")
        #expect(result.analysis == "Analysis here.\n---\nExtra section.")
    }

    @Test("Trims whitespace from both parts")
    func trimsWhitespace() {
        let raw = "  Cleaned text.  \n---\n  Some analysis.  "
        let result = parseHumanizeResponse(raw)
        #expect(result.text == "Cleaned text.")
        #expect(result.analysis == "Some analysis.")
    }

    @Test("Empty analysis after delimiter returns nil")
    func emptyAnalysisReturnsNil() {
        let raw = "Just the text.\n---\n   "
        let result = parseHumanizeResponse(raw)
        #expect(result.text == "Just the text.")
        #expect(result.analysis == nil)
    }

    // MARK: - Heuristic fallback (no delimiter)

    @Test("Strips bold Rewritten Version header")
    func stripsBoldRewrittenHeader() {
        let raw = "**Rewritten Version:**\nHere is the cleaned text.\n\n**What makes this obviously AI:**\nOveruse of em-dashes."
        let result = parseHumanizeResponse(raw)
        #expect(result.text == "Here is the cleaned text.")
        #expect(result.analysis == "Overuse of em-dashes.")
    }

    @Test("Strips markdown ## Rewritten header")
    func stripsMarkdownRewrittenHeader() {
        let raw = "## Rewritten\nCleaned output.\n\n## What makes this obviously AI\nToo formal."
        let result = parseHumanizeResponse(raw)
        #expect(result.text == "Cleaned output.")
        #expect(result.analysis == "Too formal.")
    }

    // MARK: - Plain text (no structure)

    @Test("Plain text with no structure returns as-is with nil analysis")
    func plainTextNoStructure() {
        let raw = "Just a simple rewritten sentence with no headers."
        let result = parseHumanizeResponse(raw)
        #expect(result.text == "Just a simple rewritten sentence with no headers.")
        #expect(result.analysis == nil)
    }

    @Test("Multi-paragraph plain text returns as-is")
    func multiParagraphPlainText() {
        let raw = "First paragraph.\n\nSecond paragraph."
        let result = parseHumanizeResponse(raw)
        #expect(result.text == "First paragraph.\n\nSecond paragraph.")
        #expect(result.analysis == nil)
    }
}
