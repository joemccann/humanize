# Humanize Task Plan

## Tracked tasks

- [x] T1: Finalize architecture, provider abstraction, and acceptance criteria
- [x] T2: Add provider adapter interfaces and one provider implementation
- [x] T3: Implement deterministic local rewrite pass for high-signal transformations
- [x] T4: Build paste → transform → review/copy web workflow
- [x] T5: Add tests (unit + integration + UI smoke)
  - outcome: deterministic rewrite, provider fallback, and UI-state contracts covered.
  - notes:
    - Added unit tests for deterministic rewrite and fallback behavior.
    - Added HTTP integration tests for API contracts.
    - UI validated in manual desktop and mobile checks.
- [x] T6: Add local model adapter wiring + quality/perf checks
  - outcome: Local-first routing with LM Studio auto-detection.
  - features:
    - LM Studio auto-discovery for loaded models and API flavor (`openai`/`lmstudio`).
    - Timeout handling with longer windows for larger local models.
    - Lite prompt fallback when input size threatens context limits.
    - `<think>` tag stripping for cleaner local output.

## Notes

- UI transitioned from standard cards to a two-column editorial layout.
- Local provider supports LM Studio configuration and auto-configuration paths by default.
