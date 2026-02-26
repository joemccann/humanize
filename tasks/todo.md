# Humanize Task Plan

- [x] T1: Finalize architecture, provider abstraction, and acceptance criteria
- [x] T2: Add provider adapter interfaces and one provider implementation
- [x] T3: Implement deterministic local rewrite pass for high-signal transformations
- [x] T4: Build paste → transform → review/copy web workflow
- [x] T5: Add tests (unit + integration + UI smoke)
  - outcome: coverage for rewrite contract, provider fallback, and UI state transitions
  - notes:
    - Added unit tests for deterministic rewrite and fallback behavior.
    - Added HTTP integration tests for API contracts.
    - UI overhauled to "Modern Editorial Manifesto" style; manual validation complete.
- [x] T6: Add local model adapter wiring + quality/perf checks
  - outcome: Intelligent local-first routing with auto-detection for LM Studio.
  - features:
    - Auto-detection of loaded models and API flavor (OpenAI/LM Studio).
    - Robust timeout handling (increased to 120s for large models).
    - "Lite" system prompt fallback for context-constrained models.
    - Automatic <think> tag stripping for cleaner local output.

## Notes

- UI transitioned from standard card-based design to High-Contrast Editorial Manifesto.
- Local provider now supports LM Studio auto-configuration out of the box.
