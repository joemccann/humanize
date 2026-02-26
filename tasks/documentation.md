# Humanize Documentation Log

## Status

- **Current State:** UI Overhaul (Modern Editorial Manifesto) + Robust Local Provider
- **Last updated:** 2026-02-25 (Session Overhaul)

## Milestone decisions

- **UI/UX Overhaul:** Adopted the "Modern Editorial Manifesto" style. Inverted high-contrast palette (#e8e6e1 paper, #0a0a0c canvas), Fraunces/Manrope typography, and a 3% global grain overlay. Shifted from card-based grid to a high-impact split-pane "Manifesto" layout.
- **Provider Error Mapping:** Refactored `src/server.ts` to honor `ProviderError.status`. This ensures that provider-level failures (like invalid API keys) return 401/422/502 instead of generic 500s.
- **Intelligent Local Detection:** Implemented `getDetectedLocalModel` in `src/server.ts`. The server now probes `http://localhost:1234` on startup to detect loaded LM Studio models and automatically configures the provider model name and API flavor.
- **Large Input Strategy:** Added `tasks/humanizer-system-prompt-lite.md`. Local provider now automatically switches to this "Lite" prompt when input exceeds 2000 characters to prevent context window overflows (targeting LM Studio's 4096-token default).
- **Reasoning Artifact Removal:** Added regex post-processing in `src/providers/local.ts` to strip `<think>...</think>` tags from local model outputs, ensuring a clean "Humanized" result.
- **Timeout Extension:** Increased default local model timeout to 120 seconds to accommodate 30B+ models running on consumer hardware.

## How to run / demo

- `npm run dev` (defaults to port 3000)
- `PORT=3001 npm run dev`
- Open `http://localhost:3001`
- Use the **Settings** panel to add BYOK keys if local model is unavailable.

## Known issues / follow-ups

- **Local Latency:** Large models (35B+) can take 30-60s for full generation; UI pulsing state indicates "Transforming".
- **Context Length:** Some inputs might still hit context limits if both input and output are massive; the UI now reports a clear 413 error with a suggestion to increase LM Studio's context length.
