#!/usr/bin/env python3
"""
Prompt quality evaluation for Humanize.
Sends test samples through the system prompt via OpenAI (gpt-4o-mini),
then judges output quality via Anthropic (Claude Sonnet).
Combines LLM judge scores with deterministic metrics for reduced variance.
"""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.request
import urllib.error
from pathlib import Path
from typing import Optional, Dict, List

SCRIPT_DIR = Path(__file__).parent
SAMPLES_FILE = SCRIPT_DIR / "samples.json"
JUDGE_PROMPT_FILE = SCRIPT_DIR / "judge_prompt.txt"
SYSTEM_PROMPT_FILE = SCRIPT_DIR / ".." / "shared" / "Sources" / "SystemPrompt.swift"

OPENAI_KEY = os.environ.get("OPENAI_API_KEY", "")
ANTHROPIC_KEY = os.environ.get("ANTHROPIC_API_KEY", "")

# AI words/phrases to check deterministically
AI_WORDS = [
    "additionally", "crucial", "delve", "enhance", "fostering", "foster",
    "intricate", "pivotal", "underscore", "vibrant", "leverage", "leveraging",
    "comprehensive", "robust", "transformative", "groundbreaking",
    "revolutionary", "unprecedented", "cutting-edge", "seamless",
    "serves as", "stands as", "it's important to note", "i hope this helps",
    "in today's", "rapidly evolving", "game-changer", "paradigm",
    "innovative", "remarkable", "testament", "catalyst", "holistic",
    "synergy", "empower", "navigate", "landscape", "ecosystem",
    "harness", "streamline", "optimize",
]

CHATBOT_ARTIFACTS = [
    "i hope this helps", "i hope this email finds you",
    "feel free to", "don't hesitate to",
    "it's worth noting", "it's important to note",
    "in conclusion",
]


def extract_system_prompt() -> str:
    content = SYSTEM_PROMPT_FILE.read_text()
    match = re.search(r'public let humanizeSystemPrompt = """(.*?)"""', content, re.DOTALL)
    if not match:
        print("ERROR: Could not extract system prompt", file=sys.stderr)
        sys.exit(1)
    return match.group(1).strip()


def api_call(url: str, headers: dict, body: dict, timeout: int = 45) -> dict:
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
    user_msg = (
        f'Rewrite this text:\n\n{input_text}\n\n'
        f'Options:\n{{"tone": "natural", "preserveMeaning": true}}'
    )
    body = {
        "model": "gpt-4o-mini",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_msg},
        ],
        "max_completion_tokens": 1024,
    }
    headers = {
        "Authorization": f"Bearer {OPENAI_KEY}",
        "Content-Type": "application/json",
    }
    try:
        resp = api_call("https://api.openai.com/v1/chat/completions", headers, body)
        return resp["choices"][0]["message"]["content"]
    except Exception:
        return None


def judge_quality(original: str, rewritten: str, judge_prompt: str) -> dict | None:
    user_msg = f"ORIGINAL:\n{original}\n\nREWRITTEN:\n{rewritten}"
    body = {
        "model": "claude-sonnet-4-20250514",
        "system": judge_prompt,
        "messages": [
            {"role": "user", "content": user_msg},
        ],
        "max_tokens": 512,
    }
    headers = {
        "x-api-key": ANTHROPIC_KEY,
        "Content-Type": "application/json",
        "anthropic-version": "2023-06-01",
    }
    try:
        resp = api_call("https://api.anthropic.com/v1/messages", headers, body, timeout=60)
        content_blocks = resp.get("content", [])
        text_block = next((b for b in content_blocks if b.get("type") == "text"), None)
        if not text_block:
            return None
        raw_content = text_block["text"]
        json_match = re.search(r'\{[^{}]*\}', raw_content, re.DOTALL)
        if not json_match:
            print(f"  No JSON in judge response: {raw_content[:200]}", file=sys.stderr)
            return None
        scores = json.loads(json_match.group())
        required = [
            "overall", "naturalness", "ai_word_avoidance", "meaning_preservation",
            "rhythm_variety", "personality", "artifact_removal", "format_compliance",
            "overcorrection",
        ]
        for k in required:
            if k not in scores or not (1 <= scores[k] <= 10):
                return None
        return scores
    except Exception as e:
        print(f"  Judge error: {e}", file=sys.stderr)
        return None


def count_ai_words(text: str) -> int:
    lower = text.lower()
    return sum(lower.count(word) for word in AI_WORDS)


def count_artifacts(text: str) -> int:
    lower = text.lower()
    return sum(lower.count(phrase) for phrase in CHATBOT_ARTIFACTS)


def word_overlap(text_a: str, text_b: str) -> float:
    """Jaccard similarity of word sets — measures preservation."""
    words_a = set(re.findall(r'\w+', text_a.lower()))
    words_b = set(re.findall(r'\w+', text_b.lower()))
    if not words_a or not words_b:
        return 0.0
    return len(words_a & words_b) / len(words_a | words_b)


def sentence_length_variance(text: str) -> float:
    """Standard deviation of sentence lengths — higher = more varied."""
    sentences = re.split(r'[.!?]+', text)
    lengths = [len(s.split()) for s in sentences if s.strip()]
    if len(lengths) < 2:
        return 0.0
    mean = sum(lengths) / len(lengths)
    variance = sum((l - mean) ** 2 for l in lengths) / len(lengths)
    return variance ** 0.5


def has_format_delimiter(text: str) -> bool:
    return "\n---\n" in text or "\n---" in text.rstrip()


def compute_deterministic_scores(
    input_text: str, output_text: str, is_clean: bool
) -> dict:
    """Compute deterministic quality metrics (0-10 scale)."""
    # AI word removal (0-10)
    input_ai = count_ai_words(input_text)
    output_ai = count_ai_words(output_text)
    if input_ai > 0:
        ai_removal_pct = 1 - output_ai / input_ai
        det_ai_words = min(10, round(ai_removal_pct * 10, 1))
    else:
        det_ai_words = 10.0 if output_ai == 0 else max(0, 10 - output_ai * 2)

    # Artifact removal (0-10)
    input_artifacts = count_artifacts(input_text)
    output_artifacts = count_artifacts(output_text)
    if input_artifacts > 0:
        artifact_pct = 1 - output_artifacts / input_artifacts
        det_artifacts = min(10, round(artifact_pct * 10, 1))
    else:
        det_artifacts = 10.0 if output_artifacts == 0 else max(0, 10 - output_artifacts * 3)

    # Overcorrection for clean text (0-10)
    if is_clean:
        overlap = word_overlap(input_text, output_text)
        # High overlap = good (didn't change much). Scale: 0.9+ = 10, 0.5 = 0
        det_overcorrection = min(10, max(0, round((overlap - 0.5) / 0.4 * 10, 1)))
    else:
        det_overcorrection = None  # Not applicable for AI-heavy text

    # Rhythm variety (0-10)
    output_variance = sentence_length_variance(output_text)
    # Map: 0 variance = 2, 3+ variance = 8, 6+ = 10
    det_rhythm = min(10, max(2, round(2 + output_variance * 1.33, 1)))

    # Format compliance
    det_format = 10.0 if has_format_delimiter(output_text) else 5.0

    return {
        "det_ai_words": det_ai_words,
        "det_artifacts": det_artifacts,
        "det_overcorrection": det_overcorrection,
        "det_rhythm": det_rhythm,
        "det_format": det_format,
    }


def blend_scores(judge: dict, det: dict, is_clean: bool) -> dict:
    """Blend LLM judge scores with deterministic scores. 70% judge, 30% deterministic."""
    blended = {}

    # Direct judge scores (no deterministic equivalent)
    for k in ["naturalness", "meaning_preservation", "personality"]:
        blended[k] = judge[k]

    # Blended scores (70/30 judge/deterministic)
    blended["ai_word_avoidance"] = round(judge["ai_word_avoidance"] * 0.7 + det["det_ai_words"] * 0.3, 2)
    blended["artifact_removal"] = round(judge["artifact_removal"] * 0.7 + det["det_artifacts"] * 0.3, 2)
    blended["rhythm_variety"] = round(judge["rhythm_variety"] * 0.7 + det["det_rhythm"] * 0.3, 2)
    blended["format_compliance"] = round(judge["format_compliance"] * 0.7 + det["det_format"] * 0.3, 2)

    if is_clean and det["det_overcorrection"] is not None:
        blended["overcorrection"] = round(judge["overcorrection"] * 0.5 + det["det_overcorrection"] * 0.5, 2)
    else:
        blended["overcorrection"] = judge["overcorrection"]

    # Overall: weighted combination of all blended dimensions
    # Naturalness and ai_word_avoidance weighted most heavily (per judge prompt)
    weights = {
        "naturalness": 2.0,
        "ai_word_avoidance": 2.0,
        "meaning_preservation": 1.5,
        "rhythm_variety": 1.0,
        "personality": 1.5,
        "artifact_removal": 1.0,
        "format_compliance": 0.5,
        "overcorrection": 1.5,
    }
    weighted_sum = sum(blended[k] * w for k, w in weights.items())
    total_weight = sum(weights.values())
    blended["overall"] = round(weighted_sum / total_weight, 2)

    return blended


def main():
    if not OPENAI_KEY:
        print("ERROR: OPENAI_API_KEY not set", file=sys.stderr)
        sys.exit(1)
    if not ANTHROPIC_KEY:
        print("ERROR: ANTHROPIC_API_KEY not set", file=sys.stderr)
        sys.exit(1)

    system_prompt = extract_system_prompt()
    samples = json.loads(SAMPLES_FILE.read_text())
    judge_prompt = JUDGE_PROMPT_FILE.read_text()

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
        is_clean = sample.get("category") == "control"
        print(f"--- Evaluating: {sid} ---", file=sys.stderr)

        input_ai_count = count_ai_words(input_text)
        total_ai_words_input += input_ai_count

        # Step 1: Humanize
        rewritten = humanize_text(system_prompt, input_text)
        if not rewritten:
            print(f"  SKIP: Humanization failed", file=sys.stderr)
            failed += 1
            continue

        output_ai_count = count_ai_words(rewritten)
        total_ai_words_output += output_ai_count
        print(f"  AI words: {input_ai_count} -> {output_ai_count}", file=sys.stderr)
        print(f"  Format delimiter present: {has_format_delimiter(rewritten)}", file=sys.stderr)

        # Step 2: Deterministic scores
        det = compute_deterministic_scores(input_text, rewritten, is_clean)

        # Step 3: LLM Judge
        judge = judge_quality(input_text, rewritten, judge_prompt)
        if not judge:
            print(f"  SKIP: Judging failed", file=sys.stderr)
            failed += 1
            continue

        # Step 4: Blend
        blended = blend_scores(judge, det, is_clean)

        # Print
        score_str = " ".join(f"{k}={blended[k]}" for k in dims)
        print(f"  Scores: {score_str}", file=sys.stderr)
        if "notes" in judge:
            print(f"  Notes: {judge['notes']}", file=sys.stderr)

        for d in dims:
            totals[d] += blended[d]
        successful += 1

    if successful == 0:
        print("ERROR: No samples evaluated successfully", file=sys.stderr)
        sys.exit(1)

    avgs = {d: round(totals[d] / successful, 2) for d in dims}

    if total_ai_words_input > 0:
        ai_word_reduction = round(
            (1 - total_ai_words_output / total_ai_words_input) * 100, 1
        )
    else:
        ai_word_reduction = 100.0

    print("", file=sys.stderr)
    print(f"=== RESULTS ({successful}/{len(samples)} samples) ===", file=sys.stderr)

    for d in dims:
        print(f"METRIC {d}={avgs[d]}")
    print(f"METRIC ai_word_reduction_pct={ai_word_reduction}")
    print(f"METRIC samples_ok={successful}")
    print(f"METRIC samples_failed={failed}")


if __name__ == "__main__":
    main()
