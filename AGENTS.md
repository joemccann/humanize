# AGENTS.md

## Project context

`humanize` is a cross-platform app (macOS menu bar + iOS) that rewrites AI-generated text into natural, human-sounding prose. The codebase is a Swift monorepo with four targets: `HumanizeShared` (cross-platform library), `HumanizeBar` (macOS menu bar), `HumanizeLauncher` (macOS floating panel with global hotkey), and `HumanizeMobile` (iOS via Xcode project). Users paste text, select a tone, and receive rewritten output via Cerebras, OpenAI, or Anthropic APIs. Cerebras falls back to `gpt-oss-120b` on model_not_found, then cross-provider to OpenAI/Anthropic. Other providers stay strict. Responses are parsed into humanized text + optional AI analysis (split on `---` delimiter); a "Details" button reveals the analysis rendered as rich markdown via `AttributedString`. Analysis text is preprocessed by `formatAnalysisForDisplay()` to convert dash lists to bullet points with spacing.

The humanize orchestration flow (provider-attempt loop, result formatting, status management, clipboard copy) is centralized in `HumanizeController`, a shared `@Observable` class. Both macOS PopoverView and iOS HumanizeViewModel delegate to it. All API requests have a 30-second timeout. In-flight requests are cancelled on clear or new humanize calls. The model candidate cache has a 1-hour TTL.

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
- Keep views thin — logic belongs in services, controllers, and stores.
- `HumanizeController` owns the humanize orchestration flow; views delegate to it rather than reimplementing provider loops.
- Error user-facing messages live on `HumanizeError.userFacingDescription`, not in views or view models.
- System prompt is embedded in `SystemPrompt.swift`, not fetched at runtime.
- No third-party dependencies (except `KeyboardShortcuts` for HumanizeLauncher); use Foundation and SwiftUI APIs.
- Shared code in `HumanizeShared` must be platform-agnostic (use `#if os()` only where necessary).
- iOS targets are conditionally included in Package.swift so `swift test` works on macOS without UIKit.

## Validation policy

- `swift build` must compile with zero errors and zero warnings.
- `swift test` must pass all shared + macOS + launcher tests (212 tests, 29 suites) before any merge.
- `xcodebuild test` with `HumanizeMobileTests` scheme must pass all iOS tests.
- `bash scripts/build-app.sh` must produce a signed `.app` bundle.

## Process

1. **Plan**: write milestones in `docs/todo.md`.
2. **Edit**: make targeted changes aligned to the active milestone.
3. **Verify**: run `swift build && swift test` after changes. For iOS: build in Xcode.
4. **Observe & Repair**: fix failures before moving forward.
5. **Document**: update `docs/todo.md` and `docs/lessons.md` as needed.

## Key files

| File | Purpose |
|---|---|
| `shared/Sources/Types.swift` | Shared enums and models |
| `shared/Sources/HumanizeAPIService.swift` | API request orchestration |
| `shared/Sources/SettingsStore.swift` | Persisted user preferences |
| `shared/Sources/SystemPrompt.swift` | Embedded rewrite prompt |
| `shared/Sources/TextUtilities.swift` | Text normalization, formatting, response parsing, analysis display |
| `shared/Sources/HumanizeController.swift` | Shared @Observable orchestration (provider-attempt loop, status, clipboard) |
| `shared/Sources/Clipboard.swift` | Cross-platform ClipboardProvider protocol |
| `shared/Sources/AppAppearance.swift` | Appearance enum with macOS resolver |
| `macos/Sources/HumanizeBarApp.swift` | macOS app entry point |
| `macos/Sources/AppDelegate.swift` | Menu bar status item + popover |
| `macos/Sources/PopoverView.swift` | macOS main UI + Theme |
| `ios/Sources/HumanizeMobileApp.swift` | iOS app entry point |
| `ios/Sources/HumanizeView.swift` | iOS main UI + analysis sheet |
| `ios/Sources/HumanizeViewModel.swift` | @Observable MVVM view model |
| `ios/Sources/MobileTheme.swift` | iOS adaptive color tokens |
| `shared/Tests/HumanizeTestSupport/MockHTTPClient.swift` | Shared test infrastructure |
| `launcher/Sources/HumanizeLauncherApp.swift` | Launcher app entry point |
| `launcher/Sources/PanelManager.swift` | Floating panel + global hotkey management |
| `project.yml` | XcodeGen spec for iOS project |
| `ios/Sources/Assets.xcassets/` | iOS app icon asset catalog |
| `shared/Resources/AppIcon-1024.png` | Source-of-truth app icon artwork |
| `scripts/build-app.sh` | Local signed app bundle build |
| `scripts/publish-app.sh` | Production packaging (sign, notarize, install) |
