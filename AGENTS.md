# AGENTS.md

## Project context

`humanize` is a cross-platform app (macOS menu bar + iOS) that rewrites AI-generated text into natural, human-sounding prose. The codebase is a Swift monorepo with three targets: `HumanizeShared` (cross-platform library), `HumanizeBar` (macOS), and `HumanizeMobile` (iOS via Xcode project). Users paste text, select a tone, and receive rewritten output via Cerebras, OpenAI, or Anthropic APIs. Cerebras falls back to `gpt-oss-120b` on model_not_found, then cross-provider to OpenAI/Anthropic. Other providers stay strict. Responses are parsed into humanized text + optional AI analysis (split on `---` delimiter); a "Details" button reveals the analysis.

Current provider models (from `AIProvider.defaultModel`):
- Cerebras: `zai-glm-4.7` (fallback: `gpt-oss-120b`)
- OpenAI: `gpt-5.2-chat-latest`
- Anthropic: `claude-sonnet-4-6`

Runtime behavior:
- OpenAI/Anthropic query provider model catalogs with the configured API key and use the newest compatible available model.
- If a model is unavailable (`model_not_found`/`not_found_error`), request handling retries with a provider compatibility fallback.

## Tech stack

- Swift 6.0, SwiftUI, Swift Package Manager
- macOS 14+ (Sonoma), iOS 17+
- Async/await networking (`URLSession`)
- `@Observable` for state management
- Xcode project (`HumanizeMobile.xcodeproj`) for iOS target, generated via `xcodegen` from `project.yml`

## Engineering standards

- All types are `Sendable`; use `@MainActor` for UI-bound state.
- Prefer value types and protocol conformance over inheritance.
- Keep views thin — logic belongs in services and stores.
- System prompt is embedded in `SystemPrompt.swift`, not fetched at runtime.
- No third-party dependencies; use Foundation and SwiftUI APIs.
- Shared code in `HumanizeShared` must be platform-agnostic (use `#if os()` only where necessary).

## Validation policy

- `swift build` must compile with zero errors and zero warnings.
- `swift test` must pass all shared + macOS tests (163 tests, 18 suites) before any merge.
- `xcodebuild test` with `HumanizeMobileTests` scheme must pass all iOS tests (41 tests, 7 suites).
- `bash scripts/build-app.sh` must produce a signed `.app` bundle.
- Total: 204 tests across 25 suites.

## Process

1. **Plan**: write milestones in `docs/todo.md`.
2. **Edit**: make targeted changes aligned to the active milestone.
3. **Verify**: run `swift build && swift test` after changes. For iOS: build in Xcode.
4. **Observe & Repair**: fix failures before moving forward.
5. **Document**: update `docs/todo.md` and `docs/lessons.md` as needed.

## Key files

| File | Purpose |
|---|---|
| `Sources/HumanizeShared/Types.swift` | Shared enums and models |
| `Sources/HumanizeShared/HumanizeAPIService.swift` | API request orchestration |
| `Sources/HumanizeShared/SettingsStore.swift` | Persisted user preferences |
| `Sources/HumanizeShared/SystemPrompt.swift` | Embedded rewrite prompt |
| `Sources/HumanizeShared/TextUtilities.swift` | Text normalization, formatting, response parsing |
| `Sources/HumanizeShared/AppAppearance.swift` | Appearance enum with macOS resolver |
| `Sources/HumanizeBar/HumanizeBarApp.swift` | macOS app entry point |
| `Sources/HumanizeBar/AppDelegate.swift` | Menu bar status item + popover |
| `Sources/HumanizeBar/PopoverView.swift` | macOS main UI + Theme |
| `Sources/HumanizeMobile/HumanizeMobileApp.swift` | iOS app entry point |
| `Sources/HumanizeMobile/HumanizeView.swift` | iOS main UI + analysis sheet |
| `Sources/HumanizeMobile/HumanizeViewModel.swift` | @Observable MVVM view model |
| `Sources/HumanizeMobile/MobileTheme.swift` | iOS adaptive color tokens |
| `Tests/HumanizeTestSupport/MockHTTPClient.swift` | Shared test infrastructure |
| `project.yml` | XcodeGen spec for iOS project |
| `Resources/AppIcon-1024.png` | Source-of-truth app icon artwork |
| `scripts/build-app.sh` | Local signed app bundle build |
| `scripts/publish-app.sh` | Production packaging (sign, notarize, install) |
