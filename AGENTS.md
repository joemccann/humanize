# AGENTS.md

## Project context

`humanize` is a native macOS menu bar app (SwiftUI) that rewrites AI-generated text into natural, human-sounding prose. Users paste text, select a tone, and receive rewritten output via Cerebras, OpenAI, or Anthropic APIs (with provider fallback support).

Current provider models (from `AIProvider.defaultModel`):
- Cerebras: `gpt-oss-120b`
- OpenAI: `gpt-5.2-chat-latest`
- Anthropic: `claude-sonnet-4-6`

Runtime behavior:
- OpenAI/Anthropic query provider model catalogs with the configured API key and use the newest compatible available model.
- If a model is unavailable (`model_not_found`/`not_found_error`), request handling retries with a provider compatibility fallback.

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
- `swift test` must pass (152 tests, 17 suites) before any merge.
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
| `Resources/AppIcon-1024.png` | Source-of-truth app icon artwork |
| `scripts/generate-app-icons.sh` | Generate `AppIcon.iconset` + `AppIcon.icns` from source PNG |
| `scripts/publish-app.sh` | Production packaging (sign, notarize, install to `/Applications`) |
| `docs/system-prompt-lite.md` | Reference copy of the lite prompt |
| `docs/lessons.md` | Cross-session lessons learned |
