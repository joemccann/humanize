# Autoresearch Ideas: Prompt Quality — Final Status

## Result
- **54 experiments** completed over 2 sessions
- **Best prompt**: v36 at commit 2904c76
- **Score**: peak 8.48, average ~8.36 (from 4 baseline runs: 8.48, 8.36, 8.37, 8.21)
- **Improvement**: 7.38 → 8.48 peak = **+14.9%** from original baseline
- **Key metrics**: naturalness 8.25, ai_word_avoidance 9.26, personality 7.38, rhythm 7.15

## What worked (in order of impact)
1. **"Vary dramatically, contrast matters"** rhythm instruction (+0.21 overall)
2. **Tiered rewrite strategy** (3+/1-2/0 patterns) — foundational architecture
3. **Chatbot closer deletion + AI-word-free analysis** — boosted ai_word_avoidance
4. **Expanded buzzword blacklist** (30+ words) — consistency on all samples
5. **Opening variation + natural transitions** ("anyway"/"so" not "additionally")
6. **Texture/hedging guidance** ("mostly", "kind of", parenthetical asides)

## What didn't work (tried extensively)
- Self-check / final check sections (model overthinks)
- Before/after examples (distract from instructions)
- Genre-aware personality (makes formal genres too cautious)
- "Surgery not rewrite" framing (kills personality)
- Persona-style prompt rewrites (AI word removal collapses)
- Prompt shortening below ~2.5KB (loses important guidance)
- ALL-CAPS section labels (feel corporate to model)
- "Rough edges" instructions (boost rhythm but crash clean text overcorrection)
- Stronger overcorrection phrasing (neutral at best)
- Multiple tiers beyond 3 (confuses model)

## Plateau analysis
The prompt is at a local optimum for gpt-4o-mini. The remaining variance (8.21-8.48) is dominated by:
1. **LLM generation randomness** — same prompt produces different outputs
2. **LLM judge randomness** — same output can receive different scores  
3. **Personality vs overcorrection tension** — more creative instructions help AI-heavy text but hurt clean text
4. **gpt-4o-mini clean text limitation** — model can't reliably pass through unchanged text

Further improvement would require changes to the evaluation setup (off-limits) or a fundamentally different prompting paradigm.
