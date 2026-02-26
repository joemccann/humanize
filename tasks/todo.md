# Humanize Task Plan

- [x] T1: Finalize architecture, provider abstraction, and acceptance criteria
  - depends_on: []
  - outcome: explicit API contract and quality bar for rewritten output
- validation: docs checks (prompt + runbook only)
- status: completed
- [x] T2: Add provider adapter interfaces and one provider implementation (OpenAI fallback first)
  - depends_on: [T1]
  - outcome: pluggable provider path with deterministic error handling
  - validation: docs checks + provider contract sketch
  - prompt source requirement: apply `tasks/humanizer-system-prompt.md`
  - files added: `src/providers/types.ts`, `src/providers/openai.ts`, `src/providers/anthropic.ts`, `src/providers/local.ts`, `src/providers/router.ts`
  - status: OpenAI provider includes prompt loading + retry/timeout + HTTP call scaffold; Anthropic provider remains adapter placeholder while local provider is now active via deterministic rewrite.
- [x] T3: Implement deterministic local rewrite pass for high-signal transformations
  - depends_on: [T1]
  - outcome: rule-based cleanup module independent of external APIs
  - validation: local rules implemented in `src/core/deterministicRewrite.ts` and wired into `src/providers/local.ts` via `applyDeterministicRewrite`
  - files added: `src/core/deterministicRewrite.ts`
  - status: rule-based rewrite for filler phrases, AI vocabulary, em-dash normalization, rule-of-three compression, and collaborative artifact removal is now active. Applied rule metadata is surfaced through provider warnings.
- [x] T4: Build paste → transform → review/copy web workflow
  - depends_on: [T1, T2, T3]
  - outcome: one-screen end-to-end UX with loading, error, and copy states
  - validation: static page in `public/index.html` with `/api/humanize` request/response flow, provider selection panel, status+warning rendering, and copy action.
  - files added: `src/server.ts`, `src/service/humanizeService.ts`, `public/index.html`, `public/app.js`, `public/styles.css`, `package.json`, `tsconfig.json`
  - status: Paste → transform → review/copy flow implemented with deterministic/local fallback behavior and provider wiring path.
- [ ] T5: Add tests (unit + integration + UI smoke)
  - depends_on: [T2, T3, T4]
  - outcome: coverage for rewrite contract, provider fallback, and UI state transitions
  - validation: `npm test` covers unit + integration test suites
  - notes:
    - Added unit tests for deterministic rewrite and fallback behavior in `createHumanizeService`.
    - Added HTTP integration tests for `/api/humanize`, JSON error mapping, and static index route.
    - Added Node test runner scripts in `package.json`.
    - UI smoke tests are still pending pending browser harness decision.
- [ ] T6: Add local model adapter wiring + quality/perf checks
  - depends_on: [T2, T3]
  - outcome: optional offline route with configurable timeouts and fallback behavior
  - validation: fallback behavior checklist

## Notes

- Keep scope intentionally small for first pass: one primary web interface, one stable backend endpoint, and one deterministic local heuristic path.
- Progress should be reflected in `tasks/documentation.md` and `AGENTS.md` when architecture/strategy changes.
