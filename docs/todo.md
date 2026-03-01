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
- Updated validation references to current baseline: `145 tests`, `17 suites`.
- Verification complete: `swift build` and `swift test` passed (`145 tests`, `17 suites`, `0 failures`).

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
  - `swift test` (`145 tests`, `17 suites`, `0 failures`)

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
  - `swift test` (`145 tests`, `17 suites`, `0 failures`)

## Completed

- [x] T1: Finalize architecture, provider abstraction, and acceptance criteria
- [x] T2: Add provider adapter interfaces and one provider implementation
- [x] T3: Implement deterministic local rewrite pass for high-signal transformations
- [x] T4: Build paste → transform → review/copy web workflow
- [x] T5: Add tests (unit + integration + UI smoke)
- [x] T6: Add local model adapter wiring + quality/perf checks
- [x] T7: Build native macOS menu bar app (SwiftUI, BYOK, tone selection, appearance modes)
- [x] T8: Refactor repo to macOS-only — remove Node.js/TS web app, promote macos/ to root
- [x] T9: Expand test suite and coverage baseline (now 145 tests across 17 suites)
  - Unit: Types, normalizeWhitespace, SettingsStore (persistence, corruption fallback), API service edge cases
  - Integration: settings→service flows, multi-provider round-trips, provider switching
  - UI: view instantiation, NSHostingController rendering, appearance modes, AppDelegate
- [x] T10: Add production publish pipeline script (`scripts/publish-app.sh`) with release build, Developer ID signing, notarization/stapling, and install to `/Applications/HumanizeBar.app`
- [x] T11: Add app icon pipeline (`scripts/generate-app-icons.sh`) and integrate `Resources/AppIcon.icns` into build/publish bundles
- [x] T12: Finalize app icon direction (Variant E) and promote as production `Resources/AppIcon-1024.png` source art
- [x] T13: Add Cerebras as default provider with OpenAI/Anthropic fallback backup attempts

## Up next

- [ ] Keyboard shortcut (global hotkey) to toggle popover
- [ ] Sparkle or manual update mechanism
- [ ] Clipboard watch mode (auto-detect paste, offer to humanize)
