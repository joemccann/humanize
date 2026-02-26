# Humanize API Contracts

## Endpoint

- `POST /api/humanize`

## Request body

```json
{
  "text": "string",
  "options": {
    "tone": "natural",
    "preserveMeaning": true,
    "maxTokens": 1200
  },
  "provider": "auto"
}
```

- `text` required, non-empty.
- max request text length recommended: 8,000 characters initially.
- `tone` optional (`natural | casual | professional`).
- `preserveMeaning` optional boolean, default `true`.
- `provider` optional enum:
  - `openai`
  - `anthropic`
  - `local`
  - `auto` (default)
- `systemPrompt` is not user-supplied in v1 and is fixed to the canonical prompt:
  - `tasks/humanizer-system-prompt.md`

### Success response (`200`)

```json
{
  "text": "string",
  "provider": {
    "id": "openai",
    "model": "gpt-4o-mini"
  },
  "timings": {
    "totalMs": 1450,
    "providerMs": 900,
    "localMs": 120
  },
  "warnings": ["string"],
  "stats": {
    "inputLength": 240,
    "outputLength": 228,
    "editsEstimated": 4
  },
  "promptVersion": "humanizer-system-prompt:v1",
  "systemPromptUsed": true
}
```

### Error response (`4xx/5xx`)

```json
{
  "error": {
    "code": "INVALID_INPUT",
    "message": "string",
    "details": {}
  }
}
```

Allowed error codes:
- `INVALID_INPUT`
- `PAYLOAD_TOO_LARGE`
- `PROVIDER_MISCONFIGURED`
- `PROVIDER_FAILED`
- `TIMEOUT`
- `INTERNAL_ERROR`

## Non-functional requirements

- Deterministic path must be deterministic for same input/options.
- Request should complete with:
  - basic response `< 3000ms` for local-only mode
  - `< 12000ms` for cloud provider path with retry.
- No provider credentials should be echoed in responses or logs.
- System prompt file must be treated as config source-of-truth for rewrite tone/pattern behavior.
