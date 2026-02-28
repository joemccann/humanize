# Humanize Task Plan

## Completed

- [x] T1: Finalize architecture, provider abstraction, and acceptance criteria
- [x] T2: Add provider adapter interfaces and one provider implementation
- [x] T3: Implement deterministic local rewrite pass for high-signal transformations
- [x] T4: Build paste → transform → review/copy web workflow
- [x] T5: Add tests (unit + integration + UI smoke)
- [x] T6: Add local model adapter wiring + quality/perf checks
- [x] T7: Build native macOS menu bar app (SwiftUI, BYOK, tone selection, appearance modes)
- [x] T8: Refactor repo to macOS-only — remove Node.js/TS web app, promote macos/ to root
- [x] T9: Expand test suite to 116 tests across 16 suites (~95% coverage)
  - Unit: Types, normalizeWhitespace, SettingsStore (persistence, corruption fallback), API service edge cases
  - Integration: settings→service flows, multi-provider round-trips, provider switching
  - UI: view instantiation, NSHostingController rendering, appearance modes, AppDelegate

## Up next

- [ ] Code signing + notarization for distribution
- [ ] Keyboard shortcut (global hotkey) to toggle popover
- [ ] Sparkle or manual update mechanism
- [ ] Clipboard watch mode (auto-detect paste, offer to humanize)
