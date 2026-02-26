export type HumanizeTone = "natural" | "casual" | "professional";

export interface HumanizeOptions {
  tone?: HumanizeTone;
  preserveMeaning?: boolean;
  maxTokens?: number;
}

export type ProviderId = "openai" | "anthropic" | "local";

export type ProviderSelection = ProviderId | "auto";

export interface HumanizeInput {
  text: string;
  options?: HumanizeOptions;
  provider?: ProviderSelection;
}

export interface ProviderResult {
  text: string;
  provider: ProviderId;
  model?: string;
  latencyMs: number;
  warnings: string[];
}

export type ProviderErrorCode =
  | "INVALID_INPUT"
  | "PAYLOAD_TOO_LARGE"
  | "PROVIDER_MISCONFIGURED"
  | "PROVIDER_FAILED"
  | "TIMEOUT"
  | "INTERNAL_ERROR";

export interface ProviderErrorOptions {
  details?: Record<string, unknown>;
  status?: number;
}

export class ProviderError extends Error {
  readonly code: ProviderErrorCode;
  readonly details?: Record<string, unknown>;
  readonly status?: number;

  constructor(
    code: ProviderErrorCode,
    message: string,
    options: ProviderErrorOptions = {},
  ) {
    super(message);
    this.name = "ProviderError";
    this.code = code;
    this.details = options.details;
    this.status = options.status;
  }
}

export interface RewriteProvider {
  readonly id: ProviderId;
  isAvailable(): boolean;
  rewrite(input: HumanizeInput): Promise<ProviderResult>;
}

export type LocalProviderConfig = {
  endpoint?: string;
  model?: string;
  apiKey?: string;
  requestTimeoutMs?: number;
  systemPromptPath?: string;
  apiFlavor?: "auto" | "openai" | "lmstudio";
};
