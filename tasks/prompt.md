# Humanize Project Prompt

## Goals

- Build an app that rewrites pasted text to sound natural and human-written.
- Support multiple model providers (OpenAI, Anthropic, and local model paths).
- Keep behavior deterministic enough for unit-level testing on core rewrite transformations.

## Non-goals

- No platform-specific features until the web workflow is stable.
- No hidden or opaque transformation logic for the deterministic core pass.

## Hard constraints

- One-click paste/copy flow must be preserved and obvious.
- Provider failures must fail safely with clear user feedback.
- Every implementation step must be checkpointed in markdown and validated before proceeding.
- LLM rewriting behavior is defined by `tasks/humanizer-system-prompt.md` and is not duplicated inline in code.

## Deliverables

- Reusable text rewrite contract and provider interface.
- Paste → transform → review → copy web UI.
- Core deterministic rewrite rules module.
- Verification checks for each milestone.
- Milestone documentation trail.

## Done when

- Task milestones in `tasks/todo.md` are complete in sequence.
- Validation steps pass for each completed milestone before the next starts.
- `tasks/documentation.md` reflects the final status, decisions, and known follow-ups.
