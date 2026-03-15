# Humanize Task Plan

## Active milestone

### Change: Documentation synchronization before sign-off

#### Dependency Graph

- T1 -> T2
- T2 -> T3

#### Tasks

- [x] T1: Audit docs for drift vs current codebase (providers, fallback behavior, icon pipeline, validation counts) (`depends_on: []`)
- [x] T2: Update core docs (`README.md`, `AGENTS.md`, `docs/todo.md`, `docs/lessons.md`) (`depends_on: [T1]`)
- [x] T3: Verify doc claims against current validation checks (`swift build`, `swift test`) (`depends_on: [T2]`)

#### Review

- Aligned docs to current provider model: Cerebras, OpenAI, Anthropic.
- Documented fallback behavior: selected provider first, then remaining providers in recommended order when keys are configured.
- Confirmed production packaging docs for icon generation, app bundling, and publish pipeline.
- Updated validation references to current baseline: `152 tests`, `17 suites`.
- Verification complete: `swift build` and `swift test` passed (`152 tests`, `17 suites`, `0 failures`).

### Change: Prevent selecting providers without configured API keys

#### Dependency Graph

- T4 -> T5
- T5 -> T6
- T6 -> T7

#### Tasks

- [x] T4: Normalize provider selection in settings store to configured-key providers (`depends_on: []`)
- [x] T5: Disable provider options without API keys in settings UIs (`depends_on: [T4]`)
- [x] T6: Add regression tests for the provider-selection guardrail (`depends_on: [T5]`)
- [x] T7: Run `swift build` and `swift test`; record review (`depends_on: [T6]`)

#### Review

- Provider selection now requires a configured API key.
- If the selected provider has no key and another provider does, selection auto-normalizes to the first configured provider in recommended order.
- Settings UIs now disable provider controls without keys and show helper text when no providers are selectable.
- Validation passed:
  - `swift build`
  - `swift test` (`152 tests`, `17 suites`, `0 failures`)

### Change: Post-review hardening for key validation and parser robustness

#### Dependency Graph

- T8 -> T9
- T9 -> T10

#### Tasks

- [x] T8: Treat whitespace-only API keys as missing and add store regressions (`depends_on: []`)
- [x] T9: Parse Anthropic `content` by first text block (not strictly first item) and add parser regressions (`depends_on: [T8]`)
- [x] T10: Re-run verification and align test/doc claims (`depends_on: [T9]`)

#### Review

- `SettingsStore.apiKey(for:)` now trims whitespace/newlines and returns `nil` for blank keys.
- Added regression coverage for whitespace-only keys and trimmed-key behavior.
- `HumanizeAPIService.parseResponse` for Anthropic now finds the first `type == "text"` block in `content`.
- Added Anthropic parser regressions for non-text-first and multi-text-block responses.
- Tightened integration test semantics/titles for clearer behavior contracts.
- Validation passed:
  - `swift build`
  - `swift test` (`152 tests`, `17 suites`, `0 failures`)

### Change: Document provider model mapping

#### Dependency Graph

- T11 -> T12
- T12 -> T13

#### Tasks

- [x] T11: Add provider model mapping to `README.md` (`depends_on: []`)
- [x] T12: Add provider model mapping to `AGENTS.md` (`depends_on: [T11]`)
- [x] T13: Document completion in milestone tracker (`depends_on: [T12]`)

#### Review

- Added explicit provider → model mapping for Cerebras, OpenAI, and Anthropic.
- Clarified source of truth as `AIProvider.defaultModel` in `shared/Sources/Types.swift`.

### Change: Fix runtime model selection for OpenAI/Anthropic and improve error UX

#### Dependency Graph

- T14 -> T15
- T15 -> T16
- T15 -> T17
- T16 -> T17
- T17 -> T18

#### Tasks

- [x] T14: Confirm currently available OpenAI and Anthropic models using configured API keys and select latest usable model targets (`depends_on: []`)
- [x] T15: Implement robust runtime model resolution that tries newest available model first, then retries on model-not-found with compatibility fallback (`depends_on: [T14]`)
- [x] T16: Standardize error messaging/presentation to concise Apple-style status banners without raw payload dumps (`depends_on: [T15]`)
- [x] T17: Expand tests for model discovery/fallback and friendly API-error mapping (`depends_on: [T15, T16]`)
- [x] T18: Verify with `swift build` and `swift test`, then address any regressions (`depends_on: [T17]`)

#### Review

- Live model verification against configured keys:
  - OpenAI: selected `gpt-5.2-chat-latest`
  - Anthropic: selected `claude-sonnet-4-6`
- Runtime model resolution now:
  - fetches model catalogs (`/v1/models`) for OpenAI/Anthropic
  - chooses newest valid provider model
  - retries with compatibility fallback on model-availability failures.
- Error UX is now consistent and user-facing (no raw JSON payload dump in status output).
- Regression coverage added for Anthropic model fallback when provider error omits explicit error code.
- Verification complete: `swift build` and `swift test` passed (`152 tests`, `17 suites`, `0 failures`).

### Change: Enable popover resizing from lower-right corner

#### Dependency Graph

- T19 -> T20
- T20 -> T21
- T21 -> T22

#### Tasks

- [x] T19: Add shared popover size constants and clamped resize logic in app delegate (`depends_on: []`)
- [x] T20: Add bottom-right resize grip with drag gesture/cursor affordance in popover UI (`depends_on: [T19]`)
- [x] T21: Remove fixed-width hard lock so popover can resize while preserving minimum bounds (`depends_on: [T20]`)
- [x] T22: Verify build/tests and relaunch app bundle (`depends_on: [T21]`)

#### Review

- Added `PopoverSizing` constants for default/min/max popover dimensions.
- Implemented `AppDelegate` resize callback plumbing so drag translation updates `NSPopover.contentSize` with min/max clamps.
- Added bottom-right resize handle to `PopoverView` and kept default size unchanged.
- Verification complete:
  - `swift build`
  - `swift test` (`152 tests`, `17 suites`, `0 failures`)
  - `bash scripts/build-app.sh`
  - `open /Users/joemccann/dev/apps/util/humanize/HumanizeBar.app`

### Change: Resolve OpenAI unsupported temperature errors on GPT-5 models

#### Dependency Graph

- T23 -> T24
- T24 -> T25
- T25 -> T26

#### Tasks

- [x] T23: Add failing regression tests proving OpenAI payload should not include unsupported `temperature` for current models (`depends_on: []`)
- [x] T24: Run tests to confirm red state before implementation (`depends_on: [T23]`)
- [x] T25: Implement request-builder fix and align payload assertions (`depends_on: [T24]`)
- [x] T26: Re-run build/test and relaunch app bundle for manual validation (`depends_on: [T25]`)

#### Review

- Added regression tests first and confirmed they failed before code changes.
- Removed `temperature` from OpenAI chat-completions payload for current GPT-5 model family compatibility.
- Updated request payload tests to enforce that OpenAI requests omit unsupported `temperature`.
- Verification complete:
  - `swift build`
  - `swift test` (`152 tests`, `17 suites`, `0 failures`)

### Change: Remove visible lower-right resize indicator

#### Dependency Graph

- T27 -> T28

#### Tasks

- [x] T27: Remove visible corner resize glyph while preserving lower-right drag target and cursor behavior (`depends_on: []`)
- [x] T28: Verify with `swift build` and `swift test` (`depends_on: [T27]`)

## Completed

- [x] T1: Finalize architecture, provider abstraction, and acceptance criteria
- [x] T2: Add provider adapter interfaces and one provider implementation
- [x] T3: Implement deterministic local rewrite pass for high-signal transformations
- [x] T4: Build paste → transform → review/copy web workflow
- [x] T5: Add tests (unit + integration + UI smoke)
- [x] T6: Add local model adapter wiring + quality/perf checks
- [x] T7: Build native macOS menu bar app (SwiftUI, BYOK, tone selection, appearance modes)
- [x] T8: Refactor repo to macOS-only — remove Node.js/TS web app, promote macos/ to root
- [x] T9: Expand test suite and coverage baseline (now 152 tests across 17 suites)
  - Unit: Types, normalizeWhitespace, SettingsStore (persistence, corruption fallback), API service edge cases
  - Integration: settings→service flows, multi-provider round-trips, provider switching
  - UI: view instantiation, NSHostingController rendering, appearance modes, AppDelegate
- [x] T10: Add production publish pipeline script (`scripts/publish-app.sh`) with release build, Developer ID signing, notarization/stapling, and install to `/Applications/HumanizeBar.app`
- [x] T11: Add app icon pipeline (`scripts/generate-app-icons.sh`) and integrate `Resources/AppIcon.icns` into build/publish bundles
- [x] T12: Finalize app icon direction (Variant E) and promote as production `Resources/AppIcon-1024.png` source art
- [x] T13: Add Cerebras as default provider with OpenAI/Anthropic fallback backup attempts

### Change: Refactor to monorepo with iOS app

#### Dependency Graph

- T29 -> T30
- T30 -> T31
- T31 -> T32
- T32 -> T33

#### Tasks

- [x] T29: Extract `HumanizeShared` cross-platform library from `HumanizeBar` (Types, AppAppearance, HTTPClient, SystemPrompt, HumanizeAPIService, SettingsStore, TextUtilities) (`depends_on: []`)
- [x] T30: Reorganize tests into `HumanizeTestSupport`, `HumanizeSharedTests`, `HumanizeBarTests` (`depends_on: [T29]`)
- [x] T31: Create iOS app (`HumanizeMobile`) with TDD — app entry, theme, HumanizeView, settings, clipboard, integration tests (`depends_on: [T30]`)
- [x] T32: Generate Xcode project via xcodegen, verify iOS build + tests on simulator (`depends_on: [T31]`)
- [x] T33: Update all docs, build scripts verification, .gitignore (`depends_on: [T32]`)

#### Review

- Extracted 7 platform-agnostic files into `shared/Sources/` with `public` access control.
- Split `Types.swift` into `Types.swift` + `AppAppearance.swift` (with `#if os(macOS)` for `resolvedColorScheme`).
- Extracted `normalizeInputWhitespace` and `formatLatencySeconds` into `TextUtilities.swift`.
- Created `Tests/HumanizeTestSupport/MockHTTPClient.swift` as shared test infrastructure.
- Moved 11 test files from `HumanizeBarTests` to `HumanizeSharedTests` with updated imports.
- Created 6 iOS source files: HumanizeMobileApp, ContentView, HumanizeView, MobileSettingsView, MobileTheme, Clipboard.
- Created 6 iOS test files with 20 tests across 6 suites.
- `MobileTheme` mirrors macOS `Theme` with identical RGB values using `UIColor` adaptive pattern.
- Generated `HumanizeMobile.xcodeproj` via xcodegen from `project.yml`.
- Verification passed:
  - `swift build` — zero errors
  - `swift test` — 152 tests, 17 suites, 0 failures
  - `xcodebuild test` (HumanizeMobileTests, iPhone 17 Pro) — 20 tests, 6 suites, 0 failures
  - `bash scripts/build-app.sh` — signed .app bundle produced
  - Total: 172 tests across 23 suites

## Completed

- [x] T1: Finalize architecture, provider abstraction, and acceptance criteria
- [x] T2: Add provider adapter interfaces and one provider implementation
- [x] T3: Implement deterministic local rewrite pass for high-signal transformations
- [x] T4: Build paste → transform → review/copy web workflow
- [x] T5: Add tests (unit + integration + UI smoke)
- [x] T6: Add local model adapter wiring + quality/perf checks
- [x] T7: Build native macOS menu bar app (SwiftUI, BYOK, tone selection, appearance modes)
- [x] T8: Refactor repo to macOS-only — remove Node.js/TS web app, promote macos/ to root
- [x] T9: Expand test suite and coverage baseline (now 152 tests across 17 suites)
  - Unit: Types, normalizeWhitespace, SettingsStore (persistence, corruption fallback), API service edge cases
  - Integration: settings→service flows, multi-provider round-trips, provider switching
  - UI: view instantiation, NSHostingController rendering, appearance modes, AppDelegate
- [x] T10: Add production publish pipeline script (`scripts/publish-app.sh`) with release build, Developer ID signing, notarization/stapling, and install to `/Applications/HumanizeBar.app`
- [x] T11: Add app icon pipeline (`scripts/generate-app-icons.sh`) and integrate `Resources/AppIcon.icns` into build/publish bundles
- [x] T12: Finalize app icon direction (Variant E) and promote as production `Resources/AppIcon-1024.png` source art
- [x] T13: Add Cerebras as default provider with OpenAI/Anthropic fallback backup attempts
- [x] T14: Refactor to monorepo with HumanizeShared library + iOS app (172 tests, 23 suites)
- [x] T15: Structured response parsing + "See Details" feature (204 tests, 25 suites)
  - `parseHumanizeResponse` splits on `---` delimiter with heuristic fallback
  - `HumanizeResult.analysis: String?` field, wired through `parseResponse`/`humanize()`
  - iOS: Details button + analysis sheet, input maxHeight cap
  - macOS: Details button + analysis popover
  - System prompt updated with `---` output format
  - Analysis rendered as rich markdown via `AttributedString`; `formatAnalysisForDisplay()` converts dashes to `•` bullets with spacing
  - iOS app icon added via `Assets.xcassets` using shared `Resources/AppIcon-1024.png` source

- [x] T16: Architecture refactor — shared HumanizeController, unified error messages, model cache TTL, request timeout, task cancellation, clipboard protocol (212 tests, 29 suites)
  - Extracted `HumanizeController` (@Observable) as shared orchestration layer — eliminates ~100 lines of duplicated provider-attempt logic between macOS PopoverView and iOS HumanizeViewModel
  - Added `userFacingDescription` and `isCritical` computed properties to `HumanizeError` — deleted 3 separate error mapping functions
  - Added 30s request timeout to all provider request builders (Cerebras, OpenAI, Anthropic)
  - Added TTL (1 hour) to `ModelCandidateCache` with `invalidateModelCache()` for key changes
  - Fixed task cancellation: `clear()` and new `humanize()` calls cancel in-flight requests; tasks check `Task.isCancelled` before populating results
  - Fixed `MockHTTPClient` to be properly `Sendable` (removed `@unchecked`)
  - Added `ClipboardProvider` protocol in HumanizeShared for cross-platform clipboard abstraction
  - iOS `HumanizeViewModel` now delegates to `HumanizeController` instead of reimplementing orchestration
  - macOS `PopoverView` now uses `HumanizeController` instead of inline Task + local state
  - Launcher `PanelManager` now checks `Task.isCancelled` in provider loop
  - Fixed Package.swift: iOS targets conditionally included only on iOS to unblock `swift test` on macOS
  - Fixed pre-existing `SystemPromptTests` assertion mismatch ("Avoid overused AI words" → "Buzzword soup")
  - Verification:
    - `swift build` — zero errors, zero warnings
    - `swift test` — 212 tests, 29 suites, 0 failures
    - `bash scripts/build-app.sh` — signed .app bundle produced

## Up next

- [ ] Streaming response display (SSE parsing for word-by-word output)
- [ ] Undo/redo and edit history (last N humanizations)
- [ ] Diff view for changes (inline word-level diff)
- [ ] Keychain storage for API keys (replace UserDefaults plaintext)
- [ ] Codable request/response structs (replace JSONSerialization dictionaries)
- [ ] Extract PopoverView sub-views (InputCardView, OutputCardView, StatusBadgeView)
- [ ] Sparkle or manual update mechanism
- [ ] Clipboard watch mode (auto-detect paste, offer to humanize)
- [ ] iOS App Store submission preparation (icons, screenshots, metadata)
