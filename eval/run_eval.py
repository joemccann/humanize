#!/usr/bin/env python3
"""
Prompt quality evaluation for Humanize.
Sends test samples through the system prompt via Cerebras,
then judges output quality via OpenAI. Outputs METRIC lines.
"""

import json
import os
import re
import sys
import urllib.request
import urllib.error
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
SAMPLES_FILE = SCRIPT_DIR / "samples.json"
JUDGE_PROMPT_FILE = SCRIPT_DIR / "judge_prompt.txt"
SYSTEM_PROMPT_FILE = SCRIPT_DIR / ".." / "shared" / "Sources" / "SystemPrompt.swift"

CEREBRAS_KEY = os.environ.get("CEREBRAS_API_KEY", "")
OPENAI_KEY = os.environ.get("OPENAI_API_KEY", "")

# AI words to check independently (deterministic scoring component)
AI_WORDS = [
    "additionally", "crucial", "delve", "enhance", "fostering", "foster",
    "intricate", "pivotal", "underscore", "vibrant", "leverage", "leveraging",
    "comprehensive", "robust", "transformative", "groundbreaking",
    "revolutionary", "unprecedented", "cutting-edge", "seamless",
    "serves as", "stands as", "it's important to note", "i hope this helps",
    "in today's", "rapidly evolving", "game-changer", "paradigm",
]


def extract_system_prompt() -> str:
    """Extract system prompt from SystemPrompt.swift."""
    content = SYSTEM_PROMPT_FILE.read_text()
    match = re.search(r'public let humanizeSystemPrompt = """(.*?)"""', content, re.DOTALL)
    if not match:
        print("ERROR: Could not extract system prompt", file=sys.stderr)
        sys.exit(1)
    return match.group(1).strip()


def api_call(url: str, headers: dict, body: dict, timeout: int = 45) -> dict:
    """Make an API call and return parsed JSON."""
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8", errors="replace")
        print(f"  HTTP {e.code}: {error_body[:200]}", file=sys.stderr)
        raise
    except Exception as e:
        print(f"  Request error: {e}", file=sys.stderr)
        raise


def humanize_text(system_prompt: str, input_text: str) -> str | None:
    """Send text through the humanization prompt via Cerebras."""
    user_msg = (
        f'Rewrite this text:\n\n{input_text}\n\n'
        f'Options:\n{{"tone": "natural", "preserveMeaning": true}}'
    )
    body = {
        "model": "zai-glm-4.7",
        "stream": False,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_msg},
        ],
        "temperature": 0.3,
        "top_p": 1,
        "max_completion_tokens": 1024,
    }
    headers = {
        "Authorization": f"Bearer {CEREBRAS_KEY}",
        "Content-Type": "application/json",
    }
    try:
        resp = api_call("https://api.cerebras.ai/v1/chat/completions", headers, body)
        return resp["choices"][0]["message"]["content"]
    except Exception:
        return None


def judge_quality(original: str, rewritten: str, judge_prompt: str) -> dict | None:
    """Judge rewrite quality via OpenAI."""
    user_msg = f"ORIGINAL:\n{original}\n\nREWRITTEN:\n{rewritten}"
    body = {
        "model": "gpt-4o-mini",
        "messages": [
            {"role": "system", "content": judge_prompt},
            {"role": "user", "content": user_msg},
        ],
        "max_completion_tokens": 512,
        "response_format": {"type": "json_object"},
    }
    headers = {
        "Authorization": f"Bearer {OPENAI_KEY}",
        "Content-Type": "application/json",
    }
    try:
        resp = api_call("https://api.openai.com/v1/chat/completions", headers, body)
        content = resp["choices"][0]["message"]["content"]
        scores = json.loads(content)
        required = [
            "overall", "naturalness", "ai_word_avoidance", "meaning_preservation",
            "rhythm_variety", "personality", "artifact_removal", "format_compliance",
            "overcorrection",
        ]
        for k in required:
            if k not in scores or not (1 <= scores[k] <= 10):
                print(f"  Invalid score: {k}={scores.get(k)}", file=sys.stderr)
                return None
        return scores
    except Exception:
        return None


def count_ai_words(text: str) -> int:
    """Count occurrences of AI-typical words/phrases in text."""
    lower = text.lower()
    return sum(lower.count(word) for word in AI_WORDS)


def main():
    if not CEREBRAS_KEY:
        print("ERROR: CEREBRAS_API_KEY not set", file=sys.stderr)
        sys.exit(1)
    if not OPENAI_KEY:
        print("ERROR: OPENAI_API_KEY not set", file=sys.stderr)
        sys.exit(1)

    system_prompt = extract_system_prompt()
    samples = json.loads(SAMPLES_FILE.read_text())
    judge_prompt = JUDGE_PROMPT_FILE.read_text()

    # Accumulators
    dims = [
        "overall", "naturalness", "ai_word_avoidance", "meaning_preservation",
        "rhythm_variety", "personality", "artifact_removal", "format_compliance",
        "overcorrection",
    ]
    totals = {d: 0.0 for d in dims}
    total_ai_words_input = 0
    total_ai_words_output = 0
    successful = 0
    failed = 0

    for sample in samples:
        sid = sample["id"]
        input_text = sample["input"]
        print(f"--- Evaluating: {sid} ---", file=sys.stderr)

        # Count AI words in input
        input_ai_count = count_ai_words(input_text)
        total_ai_words_input += input_ai_count

        # Step 1: Humanize
        rewritten = humanize_text(system_prompt, input_text)
        if not rewritten:
            print(f"  SKIP: Humanization failed", file=sys.stderr)
            failed += 1
            continue

        # Count AI words in output (deterministic check)
        output_ai_count = count_ai_words(rewritten)
        total_ai_words_output += output_ai_count
        print(f"  AI words: {input_ai_count} -> {output_ai_count}", file=sys.stderr)

        # Check format compliance (deterministic)
        has_delimiter = "\n---\n" in rewritten or rewritten.strip().endswith("---")
        print(f"  Format delimiter present: {has_delimiter}", file=sys.stderr)

        # Step 2: Judge
        scores = judge_quality(input_text, rewritten, judge_prompt)
        if not scores:
            print(f"  SKIP: Judging failed", file=sys.stderr)
            failed += 1
            continue

        # Print per-sample scores
        score_str = " ".join(f"{k}={scores[k]}" for k in dims)
        print(f"  Scores: {score_str}", file=sys.stderr)
        if "notes" in scores:
            print(f"  Notes: {scores['notes']}", file=sys.stderr)

        for d in dims:
            totals[d] += scores[d]
        successful += 1

    if successful == 0:
        print("ERROR: No samples evaluated successfully", file=sys.stderr)
        sys.exit(1)

    # Compute averages
    avgs = {d: round(totals[d] / successful, 2) for d in dims}

    # AI word reduction ratio (deterministic bonus metric)
    if total_ai_words_input > 0:
        ai_word_reduction = round(
            (1 - total_ai_words_output / total_ai_words_input) * 100, 1
        )
    else:
        ai_word_reduction = 100.0

    print("", file=sys.stderr)
    print(f"=== RESULTS ({successful}/{len(samples)} samples) ===", file=sys.stderr)

    # Output METRIC lines to stdout
    print(f"METRIC overall={avgs['overall']}")
    print(f"METRIC naturalness={avgs['naturalness']}")
    print(f"METRIC ai_word_avoidance={avgs['ai_word_avoidance']}")
    print(f"METRIC meaning_preservation={avgs['meaning_preservation']}")
    print(f"METRIC rhythm_variety={avgs['rhythm_variety']}")
    print(f"METRIC personality={avgs['personality']}")
    print(f"METRIC artifact_removal={avgs['artifact_removal']}")
    print(f"METRIC format_compliance={avgs['format_compliance']}")
    print(f"METRIC overcorrection={avgs['overcorrection']}")
    print(f"METRIC ai_word_reduction_pct={ai_word_reduction}")
    print(f"METRIC samples_ok={successful}")
    print(f"METRIC samples_failed={failed}")


if __name__ == "__main__":
    main()
