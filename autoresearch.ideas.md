# Autoresearch: Prompt Quality — 83 Experiments Complete

## Final Result  
- **Best prompt**: v36 at commit 2904c76
- **True average**: 8.29 ± 0.14 (6 baseline runs)
- **Improvement**: 7.38 → 8.29 avg = **+12.3%**
- **Peak**: 8.48

## Optimization is complete
83 experiments across 3 sessions with every conceivable modification tried. No change consistently beats v36 beyond the ±0.14 noise floor. The prompt is at the optimization frontier for gpt-4o-mini with this evaluation setup.

## Key architecture elements (all validated as necessary)
1. Tiered strategy (3+/1-2/0) in prose format
2. "Vary dramatically, contrast matters" rhythm instruction
3. Comprehensive 30+ word buzzword list with "every single one"
4. Chatbot closer deletion in Formulaic phrases bullet
5. "Don't use AI buzzwords you just removed" in output format
6. `## Critical Rule: Don't Overcorrect` as separate section header
7. [placeholder] template in output format section
8. 10 Voice & Rhythm bullets in current order

## Fundamental constraint discovered
**Personality ↔ Overcorrection trade-off**: Any instruction that increases creative rewriting (personality up) also increases over-editing of clean text (overcorrection down). v36 sits at the Pareto-optimal balance point.
