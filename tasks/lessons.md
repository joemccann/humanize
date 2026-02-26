# Lessons Learned

## Design & UI
- **Editorial High-Contrast:** Massive typography (`15vw`) paired with sharp edges and a grain overlay creates a "premium manifesto" feel that conventional card-based designs lack.
- **Inverted Palette:** Using a light-cream (#e8e6e1) canvas with dark (#0a0a0c) text provides a tactile, "paper-like" experience.

## LLM Integration
- **Context Management:** For local models with limited context windows (e.g., 4096), a "Lite" system prompt that strips examples and detailed guidelines is effective for processing larger inputs.
- **Reasoning Noise:** Models like Qwen or DeepSeek often ignore system instructions about formatting; a simple regex to strip `<think>...</think>` tags is a more reliable post-processing step than prompt engineering alone.
- **Provider Reliability:** Mapping 401 (Invalid Key) and 413 (Payload Too Large) specifically is critical for user trust; generic 500 errors in a "BYOK" app are confusing.
- **Auto-Detection:** Probing `/v1/models` on startup to find the *currently loaded* model in LM Studio eliminates the "400 Bad Request" errors caused by mismatched model names.
