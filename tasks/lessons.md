# Lessons

- During icon design iterations, remove any ornamental element explicitly flagged by the user and regenerate only the selected variant for fast feedback.
- For new provider integrations, validate request payload field names directly against the provider's current API reference (for example `max_completion_tokens` vs `max_tokens`) and confirm streaming mode matches app parsing behavior.
- When adding provider fallback behavior, enforce provider selection constraints in the settings store and UI so a provider without a key cannot remain selected and confuse users.
- Before sign-off requests, reconcile all docs against the current working tree (not only the last commit), especially test counts/provider lists.
- Treat API keys as trimmed values in readiness checks and provider selection logic to avoid whitespace-only false positives from paste operations.
