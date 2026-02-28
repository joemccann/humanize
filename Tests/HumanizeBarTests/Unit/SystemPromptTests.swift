import Testing
@testable import HumanizeBar

@Suite("System Prompt")
struct SystemPromptTests {
    @Test("Prompt is non-empty")
    func nonEmpty() {
        #expect(!humanizeSystemPrompt.isEmpty)
    }

    @Test("Prompt contains key phrases")
    func keyPhrases() {
        #expect(humanizeSystemPrompt.contains("writing editor"))
        #expect(humanizeSystemPrompt.contains("AI-generated"))
        #expect(humanizeSystemPrompt.contains("natural"))
    }

    @Test("Lite prompt does not contain think tags instruction")
    func noThinkTags() {
        #expect(!humanizeSystemPrompt.contains("<think>"))
    }

    @Test("Prompt contains key rules")
    func keyRules() {
        #expect(humanizeSystemPrompt.contains("Avoid overused AI words"))
        #expect(humanizeSystemPrompt.contains("Vary sentence length"))
    }
}
