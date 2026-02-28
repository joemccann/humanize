# AGENTS.md

## Project context

`humanize` is a native macOS menu bar app (SwiftUI) that rewrites AI-generated text into natural, human-sounding prose. Users paste text, select a tone, and receive rewritten output via OpenAI or Anthropic APIs.

## Tech stack

- Swift 6.0, SwiftUI, Swift Package Manager
- macOS 14+ (Sonoma)
- Async/await networking (`URLSession`)
- `@Observable` for state management

## Engineering standards

- All types are `Sendable`; use `@MainActor` for UI-bound state.
- Prefer value types and protocol conformance over inheritance.
- Keep views thin — logic belongs in services and stores.
- System prompt is embedded in `SystemPrompt.swift`, not fetched at runtime.
- No third-party dependencies; use Foundation and SwiftUI APIs.

## Validation policy

- `swift build` must compile with zero errors and zero warnings.
- `swift test` must pass (116 tests, 16 suites) before any merge.
- `bash scripts/build-app.sh` must produce a signed `.app` bundle.

## Process

1. **Plan**: write milestones in `docs/todo.md`.
2. **Edit**: make targeted changes aligned to the active milestone.
3. **Verify**: run `swift build && swift test` after changes.
4. **Observe & Repair**: fix failures before moving forward.
5. **Document**: update `docs/todo.md` and `docs/lessons.md` as needed.

## Key files

| File | Purpose |
|---|---|
| `Sources/HumanizeBar/HumanizeBarApp.swift` | App entry point |
| `Sources/HumanizeBar/AppDelegate.swift` | Menu bar status item + popover |
| `Sources/HumanizeBar/PopoverView.swift` | Main UI |
| `Sources/HumanizeBar/HumanizeAPIService.swift` | API request orchestration |
| `Sources/HumanizeBar/SettingsStore.swift` | Persisted user preferences |
| `Sources/HumanizeBar/SystemPrompt.swift` | Embedded rewrite prompt |
| `docs/system-prompt-lite.md` | Reference copy of the lite prompt |
| `docs/lessons.md` | Cross-session lessons learned |
