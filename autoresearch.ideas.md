# Autoresearch: Prompt Quality — Final Report

## Result
- **64 experiments** completed
- **Best prompt**: v36 at commit 2904c76
- **Average score**: 8.30 (stdev=0.15, range=8.06-8.48)
- **Improvement from baseline**: 7.38 → 8.30 avg = **+12.5%** (peak 8.48 = +14.9%)

## Prompt is at optimization frontier
After 64 experiments spanning every conceivable angle (wording, structure, length, formatting, personas, examples, self-checks, negative rules, section ordering, emphasis techniques), no change consistently beats v36. All modifications produce scores within the ±0.15 noise band.

## What the v36 prompt does right
1. **Tiered strategy**: Clear 3+/1-2/0 framework prevents over/under-editing
2. **Dramatic rhythm contrast**: "Alternate long and short, contrast matters" is the single biggest win
3. **Comprehensive buzzword list**: 30+ words with "replace every single one"
4. **Chatbot closer deletion**: Explicit delete instruction
5. **AI-word-free analysis**: Prevents word leakage into output
6. **Separate overcorrection header**: `## Critical Rule` gets attention from gpt-4o-mini
7. **Texture/hedging guidance**: "mostly", "kind of" — adds human feel
8. **Opening variation**: Prevents formulaic starts
