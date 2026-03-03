# Task Plan

## Change: Review latest provider/fallback updates, strengthen tests, and verify green

## Dependency Graph

- T1 -> T2
- T2 -> T3
- T2 -> T4
- T3 -> T5
- T4 -> T5

## Tasks

- [x] T1: Capture baseline by running full test suite and identifying any current failures/warnings (`depends_on: []`)
- [x] T2: Review latest code changes for regression risks and missing coverage (providers, fallback order, key selection behavior) (`depends_on: [T1]`)
- [x] T3: Implement/adjust tests to cover identified gaps and behavioral contracts (`depends_on: [T2]`)
- [x] T4: Fix any code issues uncovered during review that block correctness or testability (`depends_on: [T2]`)
- [x] T5: Re-run `swift build && swift test` and confirm all tests pass (`depends_on: [T3, T4]`)

## Review

- Confirmed and retained existing correctness fixes in the latest code: whitespace-only keys are treated as missing and Anthropic parsing selects the first text block.
- Added/expanded regression tests for:
  - `AIProvider.fallbackProviders` order for every provider and recommended-order completeness (`TypesTests`).
  - `SettingsStore.providerAttemptOrder` across all providers and `selectableProviders` ordering (`SettingsStoreTests`).
  - request-header isolation (provider-incompatible headers must be absent) and token-limit payload fields (`HumanizeAPIServiceTests`).
  - malformed Cerebras response parity (`missing choices`, `empty choices`, `missing message/content`) (`HumanizeAPIServiceTests`).
- Verification passed:
  - `swift build`
  - `swift test` (`152 tests`, `17 suites`, `0 failures`)

## Change: Fix OpenAI model-not-found runtime behavior and error UX quality

## Dependency Graph

- T9 -> T10
- T10 -> T11
- T11 -> T12

## Tasks

- [x] T9: Add OpenAI model compatibility fallback (`gpt-5.3` to a supported backup) for model-availability errors (`depends_on: []`)
- [x] T10: Replace raw API payload rendering with concise user-facing error messaging and consistent status banner UI (`depends_on: [T9]`)
- [x] T11: Add regression tests for fallback behavior and friendly error formatting (`depends_on: [T10]`)
- [x] T12: Run `swift build` and `swift test`; confirm all green (`depends_on: [T11]`)

## Change: Document provider model mapping in project docs

## Dependency Graph

- T6 -> T7
- T7 -> T8

## Tasks

- [x] T6: Add explicit provider-to-model mapping in `README.md` (`depends_on: []`)
- [x] T7: Add provider model mapping to `AGENTS.md` (`depends_on: [T6]`)
- [x] T8: Update tracker with completion notes (`depends_on: [T7]`)

## Review

- Added a dedicated provider model mapping section in `README.md` under Configuration.
- Added current provider model mapping in `AGENTS.md`.
- Documented that the source of truth is `AIProvider.defaultModel` in `Sources/HumanizeShared/Types.swift`.

## Change: Resolve OpenAI/Anthropic model-availability bugs and unify error UX

## Dependency Graph

- T14 -> T15
- T15 -> T16
- T15 -> T17
- T16 -> T17
- T17 -> T18

## Tasks

- [x] T14: Confirm currently available OpenAI and Anthropic models via configured API keys; identify latest usable model per provider (`depends_on: []`)
- [x] T15: Finalize runtime model selection so each provider attempts newest available model first with safe fallback on model-not-found (`depends_on: [T14]`)
- [x] T16: Ensure in-app error banners use concise user-facing messages with consistent Apple-style visual treatment (no raw JSON payload rendering) (`depends_on: [T15]`)
- [x] T17: Add/update regression tests for model discovery/fallback and friendly error mapping (`depends_on: [T15, T16]`)
- [x] T18: Run `swift build` and `swift test`; repair failures until full pass (`depends_on: [T17]`)

## Review

- Confirmed model availability with configured API keys:
  - OpenAI latest compatible: `gpt-5.2-chat-latest`
  - Anthropic latest: `claude-sonnet-4-6`
- Finalized runtime model resolution:
  - OpenAI/Anthropic fetch `/v1/models`, choose latest provider-available candidate, and retry with compatibility fallback on model-availability failures.
- Fixed compile/runtime regressions from the refactor:
  - corrected static `buildRequest` call site
  - updated integration mocks to handle model-list preflight requests.
- Strengthened regression coverage:
  - added Anthropic fallback test when model-not-found has no explicit error code
  - aligned 500-error expectations with friendly messaging contract.
- Verification passed:
  - `swift build`
  - `swift test` (`152 tests`, `17 suites`, `0 failures`)

## Change: Add draggable bottom-right popover resize handle (default size unchanged)

## Dependency Graph

- T19 -> T20
- T20 -> T21
- T21 -> T22

## Tasks

- [x] T19: Add shared popover sizing constants (default/min/max) and clamp behavior in app-layer popover controller (`depends_on: []`)
- [x] T20: Add bottom-right resize handle with drag gesture and cursor affordance in `PopoverView` (`depends_on: [T19]`)
- [x] T21: Relax fixed-width frame constraints so popover width/height can expand or shrink within bounds (`depends_on: [T20]`)
- [x] T22: Verify via `swift build`, `swift test`, and app bundle relaunch (`depends_on: [T21]`)

## Review

- Added `PopoverSizing` constants used by both app delegate and SwiftUI view layer.
- `AppDelegate` now accepts drag translation callbacks and mutates `NSPopover.contentSize` with min/max clamping.
- `PopoverView` now shows a bottom-right resize grip (open/closed hand cursor + drag gesture), while keeping the default launch size unchanged.
- Validation passed:
  - `swift build`
  - `swift test` (`152 tests`, `17 suites`, `0 failures`)
  - `bash scripts/build-app.sh`
  - `open /Users/joemccann/dev/apps/util/humanize/HumanizeBar.app`

## Change: Fix OpenAI GPT-5 unsupported temperature parameter with test-first workflow

## Dependency Graph

- T23 -> T24
- T24 -> T25
- T25 -> T26

## Tasks

- [x] T23: Add failing regression tests asserting OpenAI request payloads for current models omit unsupported `temperature` (`depends_on: []`)
- [x] T24: Run test suite to confirm the new tests fail against current implementation (`depends_on: [T23]`)
- [x] T25: Update OpenAI request builder logic to satisfy provider constraints and pass new regressions (`depends_on: [T24]`)
- [x] T26: Re-run full verification (`swift build`, `swift test`) and relaunch app bundle (`depends_on: [T25]`)

## Review

- Added two regressions first (red state):
  - `OpenAI GPT-5 request omits unsupported temperature parameter`
  - `OpenAI GPT-5 request body excludes unsupported temperature`
- Confirmed failure before fix (`swift test`: 152 tests run, 2 failed).
- Fixed OpenAI request payload to omit `temperature` and rely on provider default for GPT-5 chat models.
- Updated prior request-builder assertions to enforce no `temperature` on OpenAI payloads.
- Verification passed:
  - `swift build`
  - `swift test` (`152 tests`, `17 suites`, `0 failures`)

## Change: Remove visible resize indicator while preserving corner resize interaction

## Dependency Graph

- T27 -> T28

## Tasks

- [x] T27: Remove the lower-right visual resize glyph and keep corner hotspot + cursor behavior (`depends_on: []`)
- [x] T28: Run verification to ensure UI change compiles and tests remain green (`depends_on: [T27]`)

## Change: Refactor to monorepo with cross-platform shared library and iOS app

## Dependency Graph

- T29 -> T30
- T30 -> T31
- T31 -> T32
- T32 -> T33

## Tasks

- [x] T29: Extract `HumanizeShared` library from `HumanizeBar` — move 7 platform-agnostic files, add `public` access, split Types.swift into Types + AppAppearance (`depends_on: []`)
- [x] T30: Reorganize tests — create `HumanizeTestSupport` with shared MockHTTPClient, move 11 test files to `HumanizeSharedTests`, update imports (`depends_on: [T29]`)
- [x] T31: Create iOS app (`HumanizeMobile`) with TDD — 6 source files, 6 test files, MobileTheme matching macOS, all tests green (`depends_on: [T30]`)
- [x] T32: Generate `HumanizeMobile.xcodeproj` via xcodegen, verify iOS simulator build + tests (`depends_on: [T31]`)
- [x] T33: Update all docs (README, AGENTS, todo, lessons, DESIGN_MEMORY), verify build scripts, update .gitignore (`depends_on: [T32]`)

## Review

- Monorepo structure: `HumanizeShared` (7 files), `HumanizeBar` (5 files), `HumanizeMobile` (6 files).
- Test structure: `HumanizeTestSupport` (shared mocks), `HumanizeSharedTests` (11 files), `HumanizeBarTests` (1 file), `HumanizeMobileTests` (6 files).
- All file paths in docs updated from `Sources/HumanizeBar/` to `Sources/HumanizeShared/` where applicable.
- Verification passed:
  - `swift build` — zero errors
  - `swift test` — 152 tests, 17 suites, 0 failures
  - `xcodebuild test` (HumanizeMobileTests) — 20 tests, 6 suites, 0 failures
  - `bash scripts/build-app.sh` — signed .app bundle
  - Total: 172 tests, 23 suites

## Change: Structured response parsing + "See Details" feature

## Dependency Graph

- T34 -> T35
- T35 -> T36
- T36 -> T37
- T37 -> T38

## Tasks

- [x] T34: Write ResponseParsingTests (RED) — 8 tests for `parseHumanizeResponse` (`depends_on: []`)
- [x] T35: Implement `parseHumanizeResponse` in TextUtilities.swift (GREEN) (`depends_on: [T34]`)
- [x] T36: Add `analysis: String?` to `HumanizeResult`, wire into `parseResponse` and `humanize()` (`depends_on: [T35]`)
- [x] T37: Update iOS ViewModel + View and macOS PopoverView with Details button + analysis overlay (`depends_on: [T36]`)
- [x] T38: Update system prompt with `---` delimiter, cap iOS input maxHeight, full verification (`depends_on: [T37]`)

## Review

- Added `parseHumanizeResponse(_:)`: splits on `\n---\n` delimiter, heuristic fallback for markdown headers, plain text passthrough.
- Added `analysis: String?` to `HumanizeResult` (backward-compatible default `nil`).
- `parseResponse` returns `(text, analysis)` tuple; `humanize()` passes analysis through.
- Updated system prompt with `## Output Format` section instructing `---` separator.
- iOS: "Details" button + `AnalysisSheetView` sheet; capped input TextEditor `maxHeight: 280`.
- macOS: "Details" button with `.popover` between Copy and Clear.
- Verification passed:
  - `swift build` — zero errors
  - `swift test` — 163 tests, 18 suites, 0 failures
  - `xcodebuild test` — 41 tests, 7 suites, 0 failures
  - `bash scripts/build-app.sh` — signed .app bundle
  - Total: 204 tests, 25 suites
  - Analysis rendered as rich markdown via `AttributedString`; `formatAnalysisForDisplay()` converts dashes to `•` bullets with spacing
  - iOS app icon added via `Assets.xcassets` using shared `Resources/AppIcon-1024.png` source
