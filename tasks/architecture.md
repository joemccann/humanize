# Humanize Architecture (T1)

## Scope and boundaries

- Target at this stage: web-first interface backed by a single HTTP rewrite API.
- Core text transformation logic must be split into:
  - deterministic/local preprocessing
  - optional LLM-based rewrite pass via provider abstraction
- UI, API, and provider layers are separable and versioned independently.

## Proposed architecture

1. Client (web)
   - Single page flow: input editor + rewritten output panel + metadata + copy button.
   - Sends text + settings to backend endpoint and displays state (`idle`, `processing`, `success`, `error`).

2. API/backend service
   - Exposes one primary endpoint: `POST /api/humanize`.
   - Validates payload size and policy constraints.
   - Delegates to `HumanizeOrchestrator`.
   - Returns normalized response shape and provider metadata.

3. Humanize orchestrator
   - `runHumanize(input, options)`:
     - run deterministic pass
     - call selected provider adapter
     - post-process and normalize output
     - compute audit metadata
   - Handles provider failover and error shaping.

4. Provider layer
   - Interface: `RewriteProvider`
   - Implementations:
     - `OpenAIProvider`
     - `AnthropicProvider`
     - `LocalProvider` (local model or offline rule-backed placeholder)
   - All provider calls MUST use a shared system prompt source loaded from `tasks/humanizer-system-prompt.md`.

## Module decomposition

- `core`
  - deterministicRewrite(input, options)
  - rule registry + token utilities
  - style/styleProfile normalization
- `providers`
  - RewriteProvider interface
  - each provider client adapter and response parser
- `service`
  - orchestrator orchestration and policy enforcement
  - logging/audit + timing
  - applies system prompt from canonical file for model-backed pass
- `ui`
  - minimal paste-transform-copy flow and provider selection panel

## Provider abstraction

```ts
export type HumanizeOptions = {
  tone?: "natural" | "casual" | "professional";
  preserveMeaning?: boolean;
  maxTokens?: number;
};

export type HumanizeInput = {
  text: string;
  options?: HumanizeOptions;
  provider?: "openai" | "anthropic" | "local" | "auto";
};

export type ProviderResult = {
  text: string;
  provider: "openai" | "anthropic" | "local";
  model?: string;
  latencyMs: number;
  warnings: string[];
};

export interface RewriteProvider {
  readonly id: "openai" | "anthropic" | "local";
  rewrite(input: HumanizeInput): Promise<ProviderResult>;
}
```

## Error and fallback model

- Validation errors:
  - empty input -> `400 INVALID_INPUT`
  - input too long -> `413 PAYLOAD_TOO_LARGE`
  - missing provider credentials for remote mode -> `422 PROVIDER_MISCONFIGURED`
- Transient provider errors:
  - retry policy: 1 retry for selected provider
  - if provider fails and `provider=auto`, fall back to secondary provider
  - if fallback fails, return last known error with `500 PROVIDER_FAILED`
- Optional local deterministic result as safety fallback when provider errors are hard

## Acceptance criteria (T1 output)

- Contract is stable enough to implement T2 and T3 against.
- Deterministic pass and provider abstraction can be tested independently.
- Endpoint behavior supports:
  - success with text + metadata
  - provider selection + fallback
  - clear, typed errors for all failure modes
- Rewrite output can be generated only after applying:
  - deterministic local pre-pass
  - policy pass with the Humanizer system prompt
