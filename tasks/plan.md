# Humanize Plan

## Milestone execution order

### T1: Finalize architecture, provider abstraction, and acceptance criteria
- depends_on: []
- validation:
  - run: `cat tasks/prompt.md`
  - run: `cat tasks/implement.md`
- stop-and-fix rule:
  - If any required spec is unclear, resolve before coding.

### T2: Add provider adapter interfaces and one provider implementation
- depends_on: [T1]
- validation:
  - run: `cat src/providers/router.ts`
  - run: `cat src/providers/openai.ts`
  - run: `cat src/providers/types.ts`
  - run: `cat tasks/humanizer-system-prompt.md` (confirm canonical rewrite prompt exists)
- stop-and-fix rule:
  - If adapter contract cannot be validated, pause and correct before T3/T4.

### T3: Implement deterministic local rewrite pass
- depends_on: [T1]
- validation:
  - run: `cat src/core/deterministicRewrite.ts`
  - run: `cat src/providers/local.ts`
- stop-and-fix rule:
  - If core pass lacks testable edge cases, add them before moving on.

### T4: Build paste → transform → review/copy web workflow
- depends_on: [T1, T2, T3]
- validation:
  - run: `cat src/server.ts`
  - run: `cat src/service/humanizeService.ts`
  - run: `cat public/index.html`
  - run: `cat public/app.js`
- stop-and-fix rule:
  - UX errors must include loading/error/copied states before milestone close.

### T5: Add tests (unit + integration + UI smoke)
- depends_on: [T2, T3, T4]
- validation:
  - run: `npm test`
  - run: `npm run test:unit`
  - run: `npm run test:integration`
- stop-and-fix rule:
  - No unchecked milestone transitions; unresolved test failures block completion.
  - Expand UI smoke coverage before completion once a browser-based test harness is added.

### T6: Add local model adapter wiring + quality/perf checks
- depends_on: [T2, T3]
- validation:
  - run: `cat tasks/todo.md`
- stop-and-fix rule:
  - Add clear fallback and timeout behavior before considering done.

## Milestone rules

- Keep milestones small enough for one coherent edit loop.
- Run verification after each milestone and repair immediately on failure.
- Always update `tasks/documentation.md` before continuing.
