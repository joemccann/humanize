#!/bin/bash
set -euo pipefail

# Prompt quality evaluation script
# Sends test samples through the humanization prompt via Cerebras,
# then judges quality via OpenAI. Outputs METRIC lines.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SAMPLES_FILE="$SCRIPT_DIR/samples.json"
JUDGE_PROMPT_FILE="$SCRIPT_DIR/judge_prompt.txt"
SYSTEM_PROMPT_FILE="$SCRIPT_DIR/../shared/Sources/SystemPrompt.swift"

# Extract system prompt from Swift file (everything between the triple quotes)
SYSTEM_PROMPT=$(sed -n '/^public let humanizeSystemPrompt = """/,/^"""/p' "$SYSTEM_PROMPT_FILE" | sed '1d;$d')

if [ -z "$SYSTEM_PROMPT" ]; then
  echo "ERROR: Could not extract system prompt" >&2
  exit 1
fi

JUDGE_PROMPT=$(cat "$JUDGE_PROMPT_FILE")

# Read sample count
SAMPLE_COUNT=$(python3 -c "import json; print(len(json.load(open('$SAMPLES_FILE'))))")

# Accumulators
total_overall=0
total_naturalness=0
total_ai_word=0
total_meaning=0
total_rhythm=0
total_personality=0
total_artifact=0
total_format=0
total_overcorrection=0
successful=0
failed=0

for i in $(seq 0 $((SAMPLE_COUNT - 1))); do
  SAMPLE_ID=$(python3 -c "import json; print(json.load(open('$SAMPLES_FILE'))[$i]['id'])")
  SAMPLE_INPUT=$(python3 -c "import json; print(json.load(open('$SAMPLES_FILE'))[$i]['input'])")

  echo "--- Evaluating sample: $SAMPLE_ID ---" >&2

  # Step 1: Send through humanization prompt via Cerebras
  USER_MSG="Rewrite this text:\n\n${SAMPLE_INPUT}\n\nOptions:\n{\"tone\": \"natural\", \"preserveMeaning\": true}"

  HUMANIZE_RESPONSE=$(curl -s --max-time 30 "https://api.cerebras.ai/v1/chat/completions" \
    -H "Authorization: Bearer $CEREBRAS_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json, sys
msg = '''$USER_MSG'''
prompt = '''$SYSTEM_PROMPT'''
print(json.dumps({
    'model': 'zai-glm-4.7',
    'stream': False,
    'messages': [
        {'role': 'system', 'content': prompt},
        {'role': 'user', 'content': msg}
    ],
    'temperature': 0.3,
    'top_p': 1,
    'max_completion_tokens': 1024
}))
")" 2>/dev/null) || {
    echo "  SKIP: Cerebras request failed" >&2
    failed=$((failed + 1))
    continue
  }

  REWRITTEN=$(python3 -c "
import json, sys
try:
    r = json.loads('''$HUMANIZE_RESPONSE''')
    print(r['choices'][0]['message']['content'])
except:
    sys.exit(1)
" 2>/dev/null) || {
    echo "  SKIP: Could not parse Cerebras response" >&2
    failed=$((failed + 1))
    continue
  }

  # Step 2: Judge the quality via OpenAI
  JUDGE_INPUT="ORIGINAL:\n${SAMPLE_INPUT}\n\nREWRITTEN:\n${REWRITTEN}"

  JUDGE_RESPONSE=$(curl -s --max-time 60 "https://api.openai.com/v1/chat/completions" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json
judge_prompt = '''$JUDGE_PROMPT'''
judge_input = '''$JUDGE_INPUT'''
print(json.dumps({
    'model': 'gpt-4o-mini',
    'messages': [
        {'role': 'system', 'content': judge_prompt},
        {'role': 'user', 'content': judge_input}
    ],
    'max_completion_tokens': 512,
    'response_format': {'type': 'json_object'}
}))
")" 2>/dev/null) || {
    echo "  SKIP: Judge request failed" >&2
    failed=$((failed + 1))
    continue
  }

  SCORES=$(python3 -c "
import json, sys
try:
    r = json.loads('''$JUDGE_RESPONSE''')
    content = r['choices'][0]['message']['content']
    scores = json.loads(content)
    for k in ['overall','naturalness','ai_word_avoidance','meaning_preservation','rhythm_variety','personality','artifact_removal','format_compliance','overcorrection']:
        assert k in scores, f'Missing {k}'
        assert 1 <= scores[k] <= 10, f'{k} out of range'
    print(json.dumps(scores))
except Exception as e:
    print(str(e), file=sys.stderr)
    sys.exit(1)
" 2>/dev/null) || {
    echo "  SKIP: Could not parse judge scores" >&2
    failed=$((failed + 1))
    continue
  }

  # Extract individual scores
  s_overall=$(python3 -c "import json; print(json.loads('$SCORES')['overall'])")
  s_naturalness=$(python3 -c "import json; print(json.loads('$SCORES')['naturalness'])")
  s_ai_word=$(python3 -c "import json; print(json.loads('$SCORES')['ai_word_avoidance'])")
  s_meaning=$(python3 -c "import json; print(json.loads('$SCORES')['meaning_preservation'])")
  s_rhythm=$(python3 -c "import json; print(json.loads('$SCORES')['rhythm_variety'])")
  s_personality=$(python3 -c "import json; print(json.loads('$SCORES')['personality'])")
  s_artifact=$(python3 -c "import json; print(json.loads('$SCORES')['artifact_removal'])")
  s_format=$(python3 -c "import json; print(json.loads('$SCORES')['format_compliance'])")
  s_overcorrection=$(python3 -c "import json; print(json.loads('$SCORES')['overcorrection'])")
  s_notes=$(python3 -c "import json; print(json.loads('$SCORES')['notes'])")

  echo "  overall=$s_overall naturalness=$s_naturalness ai_words=$s_ai_word meaning=$s_meaning" >&2
  echo "  rhythm=$s_rhythm personality=$s_personality artifacts=$s_artifact format=$s_format overcorrection=$s_overcorrection" >&2
  echo "  notes: $s_notes" >&2

  total_overall=$((total_overall + s_overall))
  total_naturalness=$((total_naturalness + s_naturalness))
  total_ai_word=$((total_ai_word + s_ai_word))
  total_meaning=$((total_meaning + s_meaning))
  total_rhythm=$((total_rhythm + s_rhythm))
  total_personality=$((total_personality + s_personality))
  total_artifact=$((total_artifact + s_artifact))
  total_format=$((total_format + s_format))
  total_overcorrection=$((total_overcorrection + s_overcorrection))
  successful=$((successful + 1))
done

if [ "$successful" -eq 0 ]; then
  echo "ERROR: No samples evaluated successfully" >&2
  exit 1
fi

# Compute averages (multiply by 100 for precision, then divide)
avg_overall=$(python3 -c "print(round($total_overall / $successful, 2))")
avg_naturalness=$(python3 -c "print(round($total_naturalness / $successful, 2))")
avg_ai_word=$(python3 -c "print(round($total_ai_word / $successful, 2))")
avg_meaning=$(python3 -c "print(round($total_meaning / $successful, 2))")
avg_rhythm=$(python3 -c "print(round($total_rhythm / $successful, 2))")
avg_personality=$(python3 -c "print(round($total_personality / $successful, 2))")
avg_artifact=$(python3 -c "print(round($total_artifact / $successful, 2))")
avg_format=$(python3 -c "print(round($total_format / $successful, 2))")
avg_overcorrection=$(python3 -c "print(round($total_overcorrection / $successful, 2))")

echo ""
echo "=== RESULTS ($successful/$SAMPLE_COUNT samples) ==="
echo "METRIC overall=$avg_overall"
echo "METRIC naturalness=$avg_naturalness"
echo "METRIC ai_word_avoidance=$avg_ai_word"
echo "METRIC meaning_preservation=$avg_meaning"
echo "METRIC rhythm_variety=$avg_rhythm"
echo "METRIC personality=$avg_personality"
echo "METRIC artifact_removal=$avg_artifact"
echo "METRIC format_compliance=$avg_format"
echo "METRIC overcorrection=$avg_overcorrection"
echo "METRIC samples_ok=$successful"
echo "METRIC samples_failed=$failed"
