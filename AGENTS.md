# AGENTS.md

## Project context

`humanize` is a text-processing app that removes signs of AI-generated writing.
The visual identity is **Modern Editorial Manifesto**: high-contrast, tactile, and authoritative.

## Current progress

- [x] **UI Overhaul:** Implemented Fraunces/Manrope typography and Inverted Manifesto layout.
- [x] **Robust Local Path:** Auto-detection for LM Studio models, <think> tag stripping, and "Lite" prompt fallback.
- [x] **Clean Error Handling:** Specific 401/413/502 error mapping for LLM providers.
- [x] **Test Coverage:** Core deterministic rules and service fallback logic verified.

## Engineering Standards (Updated)

- **Typography Pairing:** Headlines in Fraunces (weight 100-900), Body in Manrope (200-800).
- **Tone & Voice:** Authoritative, uppercase UI labels (`EXECUTE_TRANSFORMATION`, `MANIFESTO_COMPLETE`).
- **Local-First:** Proactively detect local LLMs before falling back to cloud providers.
- **Context Efficiency:** Use "Lite" prompts for large inputs to maximize local model context space.

## Roadmap

- [ ] MacOS MenuBar App (Manifesto style)
- [ ] NextJS WebApp migration (preserving vanilla CSS variables)
- [ ] iOS App

## Session handoff (2026-02-25)

- **State:** UI is fully overhauled. Local-first flow is robust and detects LM Studio.
- **To resume:** `npm run dev` and open `http://localhost:3000`.
- **Key Files:** 
  - `public/styles.css`: The "Modern Editorial Manifesto" engine.
  - `src/server.ts`: Handles model detection and error mapping.
  - `src/providers/local.ts`: Orchestrates large-input logic and thinking-tag removal.
