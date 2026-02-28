# Lessons Learned

## Architecture

- Promoting a subdirectory (`macos/`) to repo root with `git mv` preserves history cleanly.
- macOS case-insensitive filesystem causes casing collisions during renames (e.g. `tests/` vs `Tests/`). Git tracks the old casing in its index — use `git add` with the casing git reports, not the filesystem casing.
- Extracting private view helpers as internal free functions (e.g. `normalizeInputWhitespace`) is the simplest way to make SwiftUI logic testable without restructuring views.

## Swift / SwiftUI

- Swift 6 strict concurrency: capturing mutable local variables in `@Sendable` closures is a compile error. Use separate mock instances or `#expect` inside the closure instead of writing back to a captured `var`.
- `NSHostingController.view` is non-optional on macOS — `!= nil` checks always pass. Use `frame.width >= 0` or just access the view to prove it loaded.
- `@Observable` + `UserDefaults` makes a clean persistence pattern: `didSet` writes, `init` reads with fallback.
- `UserDefaults(suiteName:)` with a UUID gives fully isolated test stores — no cross-test pollution.

## Testing

- Swift Testing `@Test(arguments:)` with `CaseIterable` enums gives exhaustive coverage with zero boilerplate.
- Red/green testing: always verify both the success path AND the expected error type/payload.
- Mock `HTTPClient` protocol + `MockHTTPClient` struct covers all network paths without real HTTP calls.
- Test corrupted/invalid `UserDefaults` values to verify fallback defaults.

## LLM Integration

- Context management matters most for local models; Lite prompts significantly reduce truncation risk.
- Explicit error mapping for 401/413/429/500/502 improves user trust versus generic failures.
- System prompt embedded in code (`SystemPrompt.swift`) is simpler and more testable than runtime fetching.
