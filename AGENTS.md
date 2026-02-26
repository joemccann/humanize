# AGENTS.md

## Project context (from README)

`humanize` is a text-processing app that removes signs of AI-generated writing from user-provided text so it reads more naturally.  
Primary user flow: paste text → process automatically → present rewritten text → allow one-click copy.

Current requirements:
- Support for Anthropic API key, OpenAI API key, or local LLM backend.
- Goal: start with a simple, production-leaning text → text pipeline, then grow to richer UI/app surfaces.
- Stated roadmap: MenuBar app, NextJS web app, and iOS app.

## Suggested first milestone

1. Confirm target stack (web-first, API shape, and local fallback path).
2. Implement a reusable `humanizeText` core module with deterministic rules + model-based passes.
3. Build a lightweight input/output UI and paste/copy flow.
4. Add safety/quality checks + configurable model provider.
5. Add tests (unit + integration) before expanding product surfaces.

## Task plan skeleton

Use this dependency graph for work planning:

- T1 (must-do first): Define architecture, provider abstraction, and success criteria
  - depends_on: []
- T2: Implement provider adapters for OpenAI/Anthropic/local model selection
  - depends_on: [T1]
- T3: Implement core text transformation heuristics + API contract
  - depends_on: [T1]
- T4: Add paste → transform → copy workflow UI
  - depends_on: [T1, T2, T3]
- T5: Add tests (unit + integration) and performance checks
  - depends_on: [T2, T3, T4]
- T6: Add local model adapter wiring + quality/perf checks
  - depends_on: [T2, T3]

## Skill recommendations for next phase

- Use `feature` skill first to pin scope and acceptance criteria.
- Use `orchestration` for multi-agent work when the implementation gets split across UI, backend, and validation.
- Use `ui-skills` for practical interaction and visual polish.
- Use `design-lab` for multiple UI direction explorations before finalizing interface.
- Use `pragmatic-rust` if any Rust service/runtime is introduced for text processing.

## Process adopted from OpenAI long-horizon agent guidance

- Execution loop:
  - Plan
  - Edit
  - Verify (tests/typecheck/lint/build where available)
  - Observe
  - Repair
  - Update docs/status
  - Repeat
- Keep one authoritative specification document and a milestone plan in markdown.
- Before moving to the next milestone, validation must pass for the previous one.
- If validation fails, repair first; do not expand scope.

## Testing recommendations

- Unit tests:
  - Deterministic rewrite rules (inputs, expected outputs, edge cases).
- Integration tests:
  - End-to-end paste → transform → copy.
  - API provider failover (OpenAI/Anthropic/local unavailable/timeout).
- UI tests:
  - Browser-level test for happy path + copy feedback + loading/error states.
  - Accessibility checks on input/output and keyboard interactions.
- Provider-backed rewrite rule for all LLM-backed calls must use
  the canonical prompt at `tasks/humanizer-system-prompt.md`.
- Added test approach:
  - Node built-in test runner with `tsx/esm` loader.
  - `npm test`, `npm run test:unit`, and `npm run test:integration`.
  - `tests/unit/*.test.ts` for deterministic and service-level contracts.
  - `tests/integration/*.test.ts` for `/api/humanize` response/error contracts and static routes.

## Progress tracking

- Update `tasks/documentation.md` every milestone and whenever architecture, design, or testing decisions change.
- Update `AGENTS.md` whenever implementation direction, architecture, or testing strategy changes.

## Current execution decision

- Starting point selected: API-first implementation with a lightweight web interface as the first surface.
- First concrete deliverable focus:
  - Define a stable `humanize` contract:
    - input: raw text + optional style/profile options,
    - output: rewritten text + metadata (provider used, latency estimate, warnings, diffs).
  - Build provider abstraction early with an adapter interface:
    - `rewrite(text, options) => providerResult`
    - adapters for `anthropic`, `openai`, and `local` behind one interface.
  - Keep deterministic/local rewrite rules in a shared core so behavior is testable independent of provider.

## Current progress

- Task tracking added in `tasks/todo.md`; T1, T2, T3, and T4 are complete.
- T5 work started for this iteration:
  - unit tests cover deterministic rewrite and service provider behavior
  - integration tests cover API success/error contract and index serving
  - UI smoke tests still pending
- Documentation stack added for long-horizon reliability:
  - `tasks/prompt.md`: stable spec and acceptance criteria
  - `tasks/plan.md`: milestone execution plan and validation commands
  - `tasks/implement.md`: runbook/instruction file
  - `tasks/documentation.md`: milestone audit log and known issues
- T1 contract artifacts added:
  - `tasks/architecture.md`: system decomposition, abstraction model, fallback behavior
  - `tasks/contracts.md`: API request/response and error contract
- Canonical rewrite behavior artifact added:
  - `tasks/humanizer-system-prompt.md`
- T2/T3 implementation now includes:
  - Provider abstraction and registry in `src/providers/router.ts`.
  - OpenAI adapter with canonical prompt loading, validation, retry, and timeout policies in `src/providers/openai.ts`.
  - Deterministic rewrite engine in `src/core/deterministicRewrite.ts`.
  - Local provider now rewrites text using deterministic rules in `src/providers/local.ts`.
- Active task has moved to T5: tests and regression coverage for web + service contract.
- UI polish milestone (current):
  - Completed polished static UI pass in `public/index.html`, `public/styles.css`, and `public/app.js`.
  - Added theme system:
    - Persistent light/dark toggle with localStorage preference.
    - Respect for system color-scheme when no manual preference is stored.
  - Accessibility and interaction pass:
    - stronger focus states for controls,
    - reduced-motion guardrails,
    - clearer status, warning, and copy feedback.
  - Theme extraction note:
    - Exact `https://www.perplexity.ai/hub/blog/introducing-perplexity-computer` CSS/font tokens could not be retrieved because Cloudflare blocks that route from this environment.
    - Current implementation uses `Inter` as a practical match while keeping all theme tokens centralized for quick updates.
- Iteration A visual refresh (reference-guided):
  - Upgraded the Iteration A layout with stronger editorial polish via `ui-skills`:
    - richer tokenized gradients, glass panels, stronger hierarchy, and improved panel composition,
    - enhanced form controls, textarea treatment, and metadata card clarity,
    - refined button states, focus rings, and reduced-motion safety.
  - Updated theme styling to make both dark/light modes look materially distinct and premium.
  - Reference image provided at `~/Library/Containers/com.wiheads.paste/Data/tmp/images/CleanShot X 2026-02-25 17.08.10.png` was used as creative direction for tone and contrast balance.
- Iteration A visual refinement (2026-02-26):
  - Applied a second pass in `public/styles.css` using screenshot-driven palette direction:
    - Light mode anchored to warm paper tones with `#f8f4ea` background base and `#1c333a`-family accents.
    - Dark mode refined for slate-cyan hierarchy and improved contrast on low-light displays.
  - Reworked panel and control treatments for stronger visual hierarchy and a cleaner interface.
  - Kept behavior untouched (`public/app.js` IDs and workflow remain unchanged).
- Icon-only theme control pass (2026-02-26):
  - Installed `lucide` package to align with shadcn-style icon sourcing: `npm install lucide`.
  - Updated theme toggle to icon-only control in `public/index.html` using moon/sun icon glyphs and retained accessible label via hidden text.
  - Updated theme icon styles in `public/styles.css` for clean square icon button behavior.
  - Kept toggle semantics and theme state management in `public/app.js` (behavior unchanged beyond icon-only presentation).
- Provider testing and local model coverage update (2026-02-26):
  - `local` provider now supports an optional machine-local LLM endpoint via new `local` provider config (`endpoint`, `model`, `apiKey`, timeout, prompt path).
  - Added real `Anthropic` API invocation path (messages endpoint, retry, timeouts, canonical prompt loading) in `src/providers/anthropic.ts`.
- Added integration tests in `tests/integration/liveProvider.test.ts` for:
    - local model path (runs when `LOCAL_LLM_ENDPOINT` is set),
    - OpenAI path (runs when `OPENAI_API_KEY` is set),
    - Anthropic path (runs when `ANTHROPIC_API_KEY` is set).
    - these tests assert provider-specific output and are skipped automatically unless `HUMANIZE_LIVE_PROVIDER_TESTS=1` is set, and relevant credentials/endpoints are present.
- `npm test` scripts now run with `--import tsx/esm` to support modern Node runtimes.
- BYOK UI/product wiring update (2026-02-26):
  - Added client-side API key inputs for OpenAI and Anthropic in `public/index.html`.
  - Persisted keys in browser `localStorage` and added save/clear actions in `public/app.js`.
  - `POST /api/humanize` now accepts `openaiApiKey` and `anthropicApiKey` payload fields and uses those values when constructing runtime provider config in `src/server.ts`, allowing per-request key usage for BYOK flows.
- BYOK refinement pass (2026-02-26):
  - Added session-only mode for API keys (`#keys-ephemeral`) to support privacy-friendly usage:
    - save to `sessionStorage` and clear on tab close when enabled,
    - clear both session and persistent storage on manual clear,
    - switch automatically clears conflicting storage backend.
  - Added run metadata "Auth source" (`#providerAuth`) to surface whether BYOK or server env keys were used for each request.
- LM Studio integration update (2026-02-26):
  - Added `local.apiFlavor` support with automatic endpoint/path resolution in `src/providers/local.ts`:
    - supports `LOCAL_LLM_API_FLAVOR=lmstudio|openai|auto`.
    - auto-resolves endpoint to `/api/v1/chat` for LM Studio-style base paths.
    - sends compatible payloads for both LM Studio (`/api/v1/chat`) and OpenAI-compatible local endpoints.
    - extracts rewritten text from multiple local response shapes.
  - Server now reads `LOCAL_LLM_API_FLAVOR` in `src/server.ts` and forwards it into local provider config.
- Startup provider preference update (2026-02-26):
  - Added boot-time local model health probe in `src/server.ts`:
    - GETs local model list endpoints with short timeout from configured LM Studio/OpenAI-compatible base.
    - checks presence of `LOCAL_LLM_MODEL` when configured (or any model when not).
    - if available, boot provider order is `local -> openai -> anthropic` for `auto` mode.
    - if unavailable, boot provider order becomes `openai -> anthropic -> local`.
  - Added startup logging for local model availability and thread-through of resolved provider order into `createHumanizeHttpServer`.
- Startup default visibility update (2026-02-26):
  - Added `GET /api/provider-order` endpoint in `src/server.ts` returning resolved startup order and default provider.
- Startup default UX simplification and local-first behavior (2026-02-26):
  - Removed startup-default visibility from the top bar and metadata card to avoid user-facing startup diagnostics.
  - Kept backend startup check and provider ordering but switched local probe to default to `http://localhost:1234` when `LOCAL_LLM_ENDPOINT` is not set.
  - Enforced explicit OpenAI/Anthropic usage in UI:
    - OpenAI and Anthropic selections now block submission unless corresponding API keys are saved in settings.
    - local remains the first auto-choice when the localhost probe finds a running local model.
  - Added provider-selection hint messaging under the dropdown to surface key requirements before submit.
- Model cost defaults for API providers (2026-02-26):
  - `src/providers/openai.ts` keeps `gpt-4o-mini` as the default fallback model.
  - `src/providers/anthropic.ts` defaults to `claude-3-haiku-20240307` (lowest-tier/lowest-cost path for rewording workloads).
- Settings panel interaction polish (2026-02-26):
  - Completed settings modal behavior wiring in `public/app.js`:
    - icon-only settings launcher in topbar opens the panel
    - backdrop and close icon close handlers implemented
    - Escape-to-close with focus return to launcher
  - Tuned UI details for the updated panel shell:
    - reduced-motion compliance and transform-backed open/close transition
    - icon button touch target adjusted to ~44px
    - minor accessibility touchups for mobile behavior and focus safety

## Session handoff (2026-02-26)

- Latest commit in this local repository: `12f406b` with 37-file import of the full Humanize implementation and docs.
- I initialized git at `/Users/joemccann/dev/apps/util/humanize` during this session and committed all project files.
- Runtime state at handoff:
  - Dev server on port `3001` was actively running and has been terminated.
  - If you restart, run `npm run dev` from `/Users/joemccann/dev/apps/util/humanize` and open `http://localhost:3000`.
- Continue with existing workflow:
  - default path still uses local model first when `localhost:1234` responds with model availability,
  - BYOK OpenAI/Anthropic remains settings-required for cloud provider calls.
