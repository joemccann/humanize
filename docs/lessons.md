# Lessons Learned

## Design & UI

- High-contrast editorial layouts benefit from explicit hierarchy and panel alignment.
- Equal-height split panes on desktop improve visual balance and reduce cognitive load.
- Shared status and copy feedback wording avoids confusion and reinforces copy confidence.

## LLM Integration

- Context management matters most for local models; Lite prompts significantly reduce truncation risk.
- Reasoning artifacts are best handled with deterministic post-processing for `<think>` tags.
- Explicit error mapping for 401/413/502 improves user trust versus generic failures.
- Startup probing `/v1/models` prevents local model mismatch errors before requests start.
