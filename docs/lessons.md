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

## Testing

- Swift Testing `@Test(arguments:)` with `CaseIterable` enums gives exhaustive coverage with minimal boilerplate.
- Red/green testing: verify both the success path and the expected error type/payload.
- Mock `HTTPClient` + structured `MockHTTPClient` data keeps provider/network tests deterministic without real HTTP calls.
- Test corrupted/invalid `UserDefaults` values to confirm fallback defaults.

## Packaging / Release

- Keep one icon source of truth at `Resources/AppIcon-1024.png`; derive all iconset/icns assets from it.
- Production publish scripts should fail fast when required signing/notarization inputs are missing.
- Include explicit bundle assertions in validation (icon exists in app resources, plist icon key set).

## LLM Integration

- Context management matters most for local models; lite prompts reduce truncation risk.
- Explicit error mapping for 401/413/429/500/502 improves user trust versus generic failures.
- System prompt embedded in code (`SystemPrompt.swift`) is simpler and more testable than runtime fetching.
