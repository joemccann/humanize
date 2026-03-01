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
- [x] T10: Add production publish pipeline script (`scripts/publish-app.sh`) with release build, Developer ID signing, notarization/stapling, and install to `/Applications/HumanizeBar.app`
- [x] T11: Add app icon pipeline (`scripts/generate-app-icons.sh`) and integrate `Resources/AppIcon.icns` into build/publish bundles
- [x] T12: Finalize app icon direction (Variant E) and promote as production `Resources/AppIcon-1024.png` source art

## Up next

- [ ] Keyboard shortcut (global hotkey) to toggle popover
- [ ] Sparkle or manual update mechanism
- [ ] Clipboard watch mode (auto-detect paste, offer to humanize)
