# Lessons

- During icon design iterations, remove any ornamental element explicitly flagged by the user and regenerate only the selected variant for fast feedback.
- For new provider integrations, validate request payload field names directly against the provider's current API reference (for example `max_completion_tokens` vs `max_tokens`) and confirm streaming mode matches app parsing behavior.
- When adding provider fallback behavior, enforce provider selection constraints in the settings store and UI so a provider without a key cannot remain selected and confuse users.
- Before sign-off requests, reconcile all docs against the current working tree (not only the last commit), especially test counts/provider lists.
- Treat API keys as trimmed values in readiness checks and provider selection logic to avoid whitespace-only false positives from paste operations.
- When switching provider defaults, validate actual model availability via each provider's live `/v1/models` endpoint with the configured key before shipping hardcoded names.
- Keep API error rendering sanitized and user-facing; never surface raw JSON payloads directly in the UI status banner.
- For OpenAI chat-completions requests targeting GPT-5 family models, use `max_completion_tokens` instead of `max_tokens` to avoid runtime `unsupported_parameter` failures.
- When enabling popover resizing, do not hard-lock width in SwiftUI (`maxWidth == minWidth`); pair a resize handle with app-layer clamped `NSPopover.contentSize` updates.
- Treat provider request options as model-specific contracts: for OpenAI GPT-5 chat models, omit `temperature` when the API indicates only the default value is supported.
- For resize affordances in compact popovers, keep the corner drag hotspot functional but visually subtle or invisible unless explicitly requested.
