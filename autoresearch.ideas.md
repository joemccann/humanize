# Autoresearch: Prompt Quality — 104 experiments across 4 sessions

## Final Result
- **Best prompt**: v36 at commit 2904c76
- **True score**: 8.26 ± 0.13 (9+ baseline runs)
- **Improvement from original**: 7.38 → 8.26 = **+11.9%**

## Exhaustive validation summary
104 experiments tested every conceivable modification:
- Text wording variations (50+ word-level changes)
- Structural changes (headers, bullets, narrative, ALL-CAPS, numbered lists)
- Length variations (ultra-concise to verbose)
- Identity changes (editor, author, "publish under your name")
- Formatting (flowing paragraphs, combined bullets, emoji emphasis)
- New sections (genre awareness, anti-cliché, don't list)
- Analysis section (constrained, abstract, chain-of-thought, examples)
- Overcorrection strategies (descriptive, preserve-meaning, postscript)
- Rhythm targeting (prescriptive numbers, contrast emphasis)

## Why v36 is the ceiling
1. **Noise floor**: ±0.13 eval variance prevents detecting <0.25 improvements
2. **Pareto frontier**: personality↔overcorrection trade-off perfectly balanced
3. **Model limitation**: gpt-4o-mini can't reliably leave clean text unchanged
4. **Content > format**: bullet count, section order, heading style all neutral
5. **Identity matters**: "editor" → rule-following; "author" → personality; can't have both
