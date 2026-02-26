# Humanize Documentation Log

## Status

- Active task: T5 tests and regression pass
- Last updated: 2026-02-26

## Milestone decisions

- Chosen process source: long-horizon Codex article loop (Plan -> Edit -> Verify -> Repair -> Document).
- `AGENTS.md` updated to enforce verification before milestone progression.
- `tasks/humanizer-system-prompt.md` added as canonical rewrite instruction set.
- Added durable memory files:
  - `tasks/prompt.md`
  - `tasks/plan.md`
  - `tasks/implement.md`
  - `tasks/documentation.md`
- Added architecture contract artifacts:
  - `tasks/architecture.md`
  - `tasks/contracts.md`
- T1, T2, and T3 are now complete:
  - API contract defined for `POST /api/humanize`
  - provider abstraction and error/fallback model documented
  - module-level architecture boundaries agreed
- T2/T4 implementation details:
  - Added `src/providers/router.ts` with provider selection and fallback.
  - Added `src/providers/openai.ts` with prompt loading from `tasks/humanizer-system-prompt.md`, retry, timeout, and fetch-based request scaffolding.
  - Added deterministic rewrite engine in `src/core/deterministicRewrite.ts`.
  - Wired deterministic rewrite into `src/providers/local.ts`.
  - Added Anthropic adapter placeholder in `src/providers/anthropic.ts` as an expansion point.
  - Added `src/service/humanizeService.ts` to orchestrate local preprocessing, provider execution, and response shaping.
  - Added `src/server.ts` to serve `/api/humanize` and static assets.
  - Added `public/index.html`, `public/app.js`, and `public/styles.css` for the complete UI flow.
  - Added `package.json` and `tsconfig.json` for TypeScript execution.
- Test work for T5:
  - Added `tests/unit/deterministicRewrite.test.ts` for text rewrite behavior.
  - Added `tests/unit/humanizeService.test.ts` for fallback, validation, and provider behavior.
  - Added `tests/integration/server.test.ts` for API contract and route checks.
  - Added npm test scripts for unit/integration execution using Node's built-in test runner.

## How to run / demo (initial)

- Review scope in `tasks/prompt.md`.
- Read milestones in `tasks/plan.md`.
- Track completion in `tasks/todo.md`.

## Known issues / follow-ups

- API and web workflow wiring is now in place for local development.
- T5 now includes unit and integration coverage, but browser UI interaction tests are pending.
- Next milestone: T6 optional quality/perf hardening and local provider polish.

## Session resume notes (2026-02-26)

- Current branch commit: `12b1b5f` (includes prior handoff notes in `AGENTS.md` and `README.md`).
- To resume:
  - `cd /Users/joemccann/dev/apps/util/humanize`
  - `npm run dev`
  - Open `http://localhost:3000`
- Runtime assumptions:
  - Local-first startup probing prefers local at `localhost:1234`.
  - OpenAI/Anthropic require keys in Settings before those providers can be selected.
  - Port `3001` dev process was explicitly stopped at handoff.
