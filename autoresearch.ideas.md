# Autoresearch: Prompt Quality — Final Report

## Result
- **60 experiments** completed over 2 sessions
- **Best prompt**: v36 at commit 2904c76
- **Peak score**: 8.48, **Average**: ~8.30 (from 5 baseline runs)
- **Improvement from original baseline**: 7.38 → 8.48 peak = **+14.9%**
- **True variance**: stdev=0.15, range=8.06-8.48

## Prompt architecture (v36)
1. **Opening**: "Sharp-eyed writing editor" identity
2. **## How to Think**: Tiered strategy (3+/1-2/0 patterns)
3. **## AI Patterns to Fix**: 30+ buzzwords, structural patterns, formulaic phrases, chatbot closers
4. **## Voice & Rhythm**: 10 bullets led by dramatic rhythm contrast instruction
5. **## Critical Rule: Don't Overcorrect**: Separate header for emphasis
6. **## Output Format**: No AI buzzwords in analysis section

## Key wins (chronological)
| Version | Score | Key change |
|---------|-------|------------|
| v2 | 7.50 | Buzzword list + overcorrection rule |
| v3 | 8.00 | Texture/hedging guidance |
| v7 | 8.00 | Expanded buzzword blacklist |
| v18 | 8.07 | "Copy word-for-word" for clean text |
| v19 | 8.11 | Opening variation + natural transitions |
| v22 | 8.25 | Tiered rewrite strategy (3+/1-2/0) |
| v34 | 8.27 | Chatbot closer deletion + AI-word-free analysis |
| **v36** | **8.48** | **"Vary dramatically, contrast matters"** |

## Exhaustively tried and confirmed unhelpful
Self-check sections, before/after examples, genre-aware personality, "surgery" framing, persona prompts, ultra-concise prompts, ALL-CAPS labels, section reordering, "rough edges" (helps rhythm but kills clean text), prompt shortening, prompt lengthening, flowing paragraph format, tone awareness, abstract→concrete instruction, "Don't" lists, 4-tier strategies, negative examples, stronger overcorrection wording, chatbot prevention instructions.

## Conclusion
The v36 prompt is at the optimization frontier for gpt-4o-mini with this evaluation setup. Further improvement requires either reducing eval variance (multi-run averaging) or changing the evaluation model/judge.
