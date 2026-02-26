# Humanize Implement Runbook

## Operating assumptions

- `tasks/plan.md` is the source of truth for milestone sequence.
- `tasks/todo.md` tracks completion state.
- `tasks/documentation.md` tracks current status and rationale.

## Agent execution loop

1. Plan
2. Edit (implement one milestone only)
3. Verify (tests/lint/typecheck/build or nearest available equivalent)
4. Observe output and logs
5. Repair failures
6. Update docs/status
7. Repeat

## Rules

- Keep diffs scoped to the active milestone.
- Do not change completed milestone behavior unless a validation failure requires repair.
- If a verification command fails, stop and fix before starting the next task.
- Record decisions and blockers in `tasks/documentation.md` immediately.
- If uncertainty emerges, add a follow-up milestone to `tasks/todo.md` rather than inlining unsupported behavior.
- During T2+, every model-backed pass must inject the fixed system prompt from
  `tasks/humanizer-system-prompt.md` at call time.
- For local development of T4+, run:
  - `npm install`
  - `npm run dev`
  - open `http://localhost:3000` and use the browser flow.
