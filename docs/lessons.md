# Lessons Learned

## Architecture

- Promoting a subdirectory (`macos/`) to repo root with `git mv` preserves history cleanly.
- macOS case-insensitive filesystem causes casing collisions during renames (for example `tests/` vs `Tests/`). Git tracks the old casing in its index; use `git add` with the casing git reports.
- Extracting private view helpers as internal free functions (for example `normalizeInputWhitespace`) is the simplest way to make SwiftUI logic testable without restructuring views.
- Keep provider metadata centralized in `AIProvider` (display name, default model, recommended order) so UI, defaults, and fallback logic cannot drift.

## Swift / SwiftUI

- Swift 6 strict concurrency: capturing mutable local variables in `@Sendable` closures is a compile error. Use separate mock instances or `#expect` inside the closure instead of writing back to a captured `var`.
- `NSHostingController.view` is non-optional on macOS; `!= nil` checks always pass. Use `frame.width >= 0` or just access the view to prove it loaded.
- `@Observable` + `UserDefaults` makes a clean persistence pattern: `didSet` writes, `init` reads with fallback.
- `UserDefaults(suiteName:)` with a UUID gives fully isolated test stores with no cross-test pollution.

## Provider Integration

- Validate provider payload fields against current API docs before coding (`max_completion_tokens` vs `max_tokens`) to avoid subtle runtime failures.
- Keep response parsing per provider explicit and normalize into one shared `HumanizeResult` shape.
- Fallback behavior should be deterministic and easy to reason about: selected provider first, then remaining providers in recommended order when keys exist.
- API keys should be trimmed before readiness/selection checks so whitespace-only values are treated as missing.
- For provider model updates, verify live model catalogs (`/v1/models`) with the active API key before finalizing defaults.
- UI status surfaces should map provider failures to concise human-friendly messages rather than raw payload dumps.
- OpenAI GPT-5 chat-completions payloads should use `max_completion_tokens`; `max_tokens` can be rejected as an unsupported parameter.
- For resizable popovers, avoid fixed-width SwiftUI frames and route drag-handle deltas to clamped `NSPopover.contentSize` updates in AppKit.
- OpenAI GPT-5 chat payloads should omit `temperature` when only default temperature is supported; enforce this with regression tests.
- For popover resize UX in tight layouts, prefer an invisible corner drag target plus cursor change when explicit visual grabber marks are undesired.

## Monorepo / Cross-Platform

- When extracting a shared library from a single-target app, add `public` to every type, property, method, and init that needs cross-module visibility. Memberwise inits on structs are not auto-synthesized as `public`; add explicit `public init(...)`.
- Use `#if os(macOS)` / `#if os(iOS)` sparingly in shared code; prefer platform-specific files in each app target.
- `@_exported import` re-exports a dependency's types, but `@testable` on the re-exporting module does not grant testable access to the re-exported module's internals. Add explicit `import` or `@testable import` for each module the tests need.
- `UIPasteboard` is unreliable in iOS simulator unit tests (pasteboard UUID becomes unavailable). Test that clipboard functions execute without error rather than asserting read-back values.
- For iOS theme parity with macOS, use `UIColor { traitCollection in }` adaptive pattern with identical RGB values. This is the UIKit equivalent of `NSColor(name:) { appearance in }`.
- XcodeGen (`project.yml`) is effective for maintaining an Xcode project alongside a Package.swift monorepo. Regenerate with `xcodegen generate` after target/dependency changes.
- SPM `swift test` only runs macOS test targets. iOS tests require `xcodebuild test` with a simulator destination.

## Testing

- Swift Testing `@Test(arguments:)` with `CaseIterable` enums gives exhaustive coverage with minimal boilerplate.
- Red/green testing: verify both the success path and the expected error type/payload.
- Mock `HTTPClient` + structured `MockHTTPClient` data keeps provider/network tests deterministic without real HTTP calls.
- Test corrupted/invalid `UserDefaults` values to confirm fallback defaults.
- Extract shared test infrastructure (e.g., `MockHTTPClient`) into a non-test `.target` so multiple test targets can depend on it.

## Packaging / Release

- Keep one icon source of truth at `Resources/AppIcon-1024.png`; derive all iconset/icns assets from it.
- Production publish scripts should fail fast when required signing/notarization inputs are missing.
- Include explicit bundle assertions in validation (icon exists in app resources, plist icon key set).

## Architecture Refactoring

- When two platforms duplicate the same orchestration flow (provider-attempt loop, result formatting, clipboard copy), extract an `@Observable` controller in the shared library. Both platforms delegate to it instead of reimplementing the logic.
- Error-to-user-message mapping belongs on the error type itself (`userFacingDescription`), not scattered across views and view models.
- Model caches should have a TTL and an explicit `invalidate()` method. Without TTL, stale entries persist until app restart when providers update models or users change keys.
- Always set explicit `timeoutInterval` on `URLRequest` for API calls. Without it, a hanging provider shows an infinite spinner with no user recourse.
- When spawning `Task` from `@MainActor` views, always store the task handle and cancel it on `clear()`, dismiss, or when starting a new request. Otherwise, late-arriving results overwrite the user's current state.
- Use `Task.isCancelled` checks before mutating shared state in async provider loops. This prevents a cancelled task from populating results after the user has moved on.
- SPM `#if os(iOS)` in Package.swift conditionally includes iOS targets that depend on UIKit, preventing `swift test` from failing on macOS where UIKit is unavailable.
- `@unchecked Sendable` on immutable structs with `@Sendable` closures is unnecessary — the struct is already properly Sendable.
- For `@MainActor` async tests, use `.serialized` trait and a polling `waitUntil` helper instead of fixed `Task.sleep` durations. Parallel test execution causes main actor contention that makes fixed delays unreliable.



- Context management matters most for local models; lite prompts reduce truncation risk.
- Explicit error mapping for 401/413/429/500/502 improves user trust versus generic failures.
- System prompt embedded in code (`SystemPrompt.swift`) is simpler and more testable than runtime fetching.
- When LLM responses mix rewritten text with analysis, use a simple delimiter (`---`) in the system prompt for reliable structured parsing; add heuristic fallbacks for markdown headers as a safety net.
- iOS `TextEditor` grows unbounded by default; set `maxHeight` on input fields to prevent large pastes from pushing content off screen.
- Use `AttributedString(markdown:, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))` to render inline markdown (bold, italic) in SwiftUI `Text` while preserving line breaks. Preprocess LLM dash lists into `•` bullets with blank-line spacing for readable display.
- Modern iOS (17+) only needs a single 1024x1024 universal icon in `Assets.xcassets/AppIcon.appiconset`; Xcode derives all required sizes automatically. Share the same source PNG as macOS.
