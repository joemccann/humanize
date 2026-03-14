# Autoresearch: Prompt Quality Optimization

## Objective
Optimize the system prompt in `shared/Sources/SystemPrompt.swift` to maximize the quality of AI-text humanization. The prompt instructs LLMs to rewrite AI-generated text into natural, human-sounding prose. We evaluate quality by sending 8 diverse AI-generated text samples through the prompt via Cerebras, then scoring the output with an LLM judge on 8 dimensions.

## Metrics
- **Primary**: `overall` (1-10 scale, higher is better) — holistic judge score averaging across 8 test samples
- **Secondary**: `naturalness`, `ai_word_avoidance`, `meaning_preservation`, `rhythm_variety`, `personality`, `artifact_removal`, `format_compliance`, `overcorrection`, `ai_word_reduction_pct`

## How to Run
`./autoresearch.sh` — compiles the Swift project, then runs `eval/run_eval.py` which:
1. Extracts the system prompt from `SystemPrompt.swift`
2. Sends 8 test samples through Cerebras with the prompt
3. Judges each output via OpenAI gpt-4o-mini
4. Outputs `METRIC name=number` lines

## Files in Scope
| File | Purpose |
|---|---|
| `shared/Sources/SystemPrompt.swift` | **PRIMARY TARGET** — the system prompt to optimize |
| `eval/samples.json` | 8 test samples of AI-generated text across categories |
| `eval/judge_prompt.txt` | Judge prompt for scoring quality dimensions |
| `eval/run_eval.py` | Evaluation script orchestrating humanize + judge calls |

## Off Limits
- All other Swift source files (Types.swift, HumanizeAPIService.swift, etc.)
- Test files
- Build scripts
- macOS/iOS app code

## Constraints
- `swift build` must compile with zero errors (prompt is embedded in Swift code)
- `swift test` must pass all 204 tests (checked via autoresearch.checks.sh)
- The prompt must maintain the `---` delimiter output format (rewritten text, then `---`, then analysis)
- No changes to the Swift variable declaration (`public let humanizeSystemPrompt = """`)
- The prompt must work with all three providers (Cerebras, OpenAI, Anthropic)
- Keep prompt under ~2000 tokens to avoid truncation issues
- Preserve the core task: rewriting AI-generated text to sound human

## What's Been Tried
(Will be updated as experiments accumulate)

### Baseline
- Current prompt: Simple 4-step task, key rules list, output format example
- Baseline score: TBD (first run)
