import {
  HumanizeInput,
  ProviderError,
  ProviderResult,
  HumanizeOptions,
  RewriteProvider,
  LocalProviderConfig,
} from "./types";
import { applyDeterministicRewrite } from "../core/deterministicRewrite";
import { promises as fs } from "node:fs";
import * as path from "node:path";

export class LocalProvider implements RewriteProvider {
  readonly id = "local" as const;
  private readonly endpoint?: string;
  private readonly model: string;
  private readonly apiKey?: string;
  private readonly requestTimeoutMs: number;
  private readonly systemPromptPath: string;
  private readonly apiFlavor: "auto" | "openai" | "lmstudio";
  private systemPromptCache: string | null = null;

  constructor(config: LocalProviderConfig = {}) {
    this.endpoint = config.endpoint;
    this.model = config.model ?? "local";
    this.apiKey = config.apiKey;
    this.requestTimeoutMs = config.requestTimeoutMs ?? 120000;
    this.apiFlavor = config.apiFlavor ?? "auto";
    this.systemPromptPath =
      config.systemPromptPath ??
      path.resolve(process.cwd(), "tasks", "humanizer-system-prompt.md");
  }

  private async getSystemPrompt(isLargeInput: boolean): Promise<string> {
    if (isLargeInput) {
      console.log("[LocalProvider] Large input detected, using 'Lite' system prompt to save context space.");
    }
    const promptPath = isLargeInput 
      ? path.resolve(process.cwd(), "tasks", "humanizer-system-prompt-lite.md")
      : this.systemPromptPath;

    try {
      const prompt = await fs.readFile(promptPath, "utf8");
      const normalized = prompt.trim();
      if (!normalized) {
        throw new ProviderError(
          "PROVIDER_MISCONFIGURED",
          `System prompt file is empty: ${promptPath}`,
        );
      }
      return normalized;
    } catch (_error) {
      // If lite prompt fails to load, fallback to default
      if (isLargeInput && promptPath !== this.systemPromptPath) {
        return this.getSystemPrompt(false);
      }
      throw new ProviderError(
        "PROVIDER_MISCONFIGURED",
        `Failed to load system prompt: ${promptPath}`,
      );
    }
  }

  private async callLocalModel(
    text: string,
    options: HumanizeOptions,
  ): Promise<string> {
    if (!this.endpoint) {
      throw new ProviderError("PROVIDER_MISCONFIGURED", "Local model endpoint is not configured");
    }

    try {
      const isLarge = text.length > 2000;
      const systemPrompt = await this.getSystemPrompt(isLarge);
      const endpoint = this.resolveLocalEndpoint(this.endpoint);
      const requestBody = this.buildRequestBody(systemPrompt, text, options);
      
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(this.apiKey ? { Authorization: `Bearer ${this.apiKey}` } : {}),
        },
        signal: AbortSignal.timeout(this.requestTimeoutMs),
        body: JSON.stringify(requestBody),
      });

      if (!response.ok) {
        let errorDetails = "";
        try {
          const errorPayload = await response.json();
          errorDetails = JSON.stringify(errorPayload);
        } catch {
          errorDetails = await response.text();
        }
        
        if (errorDetails.includes("n_ctx") || errorDetails.includes("context length")) {
          throw new ProviderError(
            "PAYLOAD_TOO_LARGE",
            "The text is too long for the local model's current context window. Try increasing 'Context Length' in LM Studio settings.",
            { status: 413 }
          );
        }

        throw new ProviderError(
          "PROVIDER_FAILED",
          `Local model request failed (${response.status}): ${errorDetails}`,
          { status: response.status },
        );
      }

      const payload = (await response.json()) as any;
      const rewritten = this.extractRewrittenText(payload);

      if (typeof rewritten !== "string" || !rewritten.trim()) {
        throw new ProviderError(
          "PROVIDER_FAILED",
          "Local model returned an empty rewritten result",
        );
      }

      return rewritten.trim();
    } catch (error) {
      if (error instanceof ProviderError) {
        throw error;
      }
      if (
        (error as Error).name === "TimeoutError" ||
        (error as Error).name === "AbortError"
      ) {
        throw new ProviderError("TIMEOUT", "Local model request timed out");
      }
      const originalMessage = (error as Error).message ?? String(error);
      throw new ProviderError("PROVIDER_FAILED", `Local model request failed: ${originalMessage}`, {
        details: { source: originalMessage },
      });
    }
  }

  private resolveLocalEndpoint(endpoint: string): string {
    const trimmed = endpoint.trim().replace(/\/$/, "");
    
    // If it already looks like a full chat completions endpoint, return it
    if (trimmed.endsWith("/v1/chat/completions") || 
        trimmed.endsWith("/api/v1/chat") || 
        trimmed.endsWith("/v1/chat")) {
      return trimmed;
    }

    // LM Studio specific or auto-detected flavor handling
    if (this.apiFlavor === "lmstudio") {
      return `${trimmed}/api/v1/chat`;
    }

    if (this.apiFlavor === "openai") {
      return `${trimmed}/v1/chat/completions`;
    }

    // Fallback/Auto logic for base URLs
    if (trimmed.endsWith(":1234")) {
      // Very likely LM Studio default
      return `${trimmed}/v1/chat/completions`;
    }

    return `${trimmed}/v1/chat/completions`;
  }

  private buildRequestBody(
    systemPrompt: string,
    text: string,
    options: HumanizeOptions,
  ): Record<string, unknown> {
    const content = `Rewrite this text:\n\n${text}\n\nOptions:\n${JSON.stringify(
      {
        tone: options.tone,
        preserveMeaning: options.preserveMeaning,
        maxTokens: options.maxTokens,
      },
      null,
      2,
    )}`;

    const baseMessages = [
      {
        role: "system",
        content: systemPrompt,
      },
      {
        role: "user",
        content,
      },
    ];

    const tokens = options.maxTokens;
    const basePayload: Record<string, unknown> = {
      model: this.model,
      messages: baseMessages,
    };

    if (tokens !== undefined) {
      basePayload.max_tokens = tokens;
      basePayload.max_completion_tokens = tokens;
    }

    if (this.apiFlavor === "lmstudio" || this.shouldUseLMStudioEndpoint()) {
      return {
        ...basePayload,
        stream: false,
      };
    }

    return basePayload;
  }

  private shouldUseLMStudioEndpoint(): boolean {
    if (this.apiFlavor === "lmstudio") {
      return true;
    }
    if (this.apiFlavor === "openai") {
      return false;
    }

    if (!this.endpoint) {
      return false;
    }

    const normalized = this.endpoint.trim().replace(/\/$/, "");
    return (
      normalized.includes("/api/v1/chat") ||
      normalized.endsWith("/api/v1") ||
      normalized.endsWith("/api")
    );
  }

  private extractRewrittenText(payload: unknown): string | undefined {
    if (!payload || typeof payload !== "object") {
      return undefined;
    }

    const toText = (value: unknown): string | undefined => {
      if (typeof value === "string") {
        return value;
      }

      if (Array.isArray(value)) {
        const first = value[0];
        const mapped = this.extractRewrittenText(first);
        if (mapped) {
          return mapped;
        }
      }

      if (
        value &&
        typeof value === "object" &&
        "text" in value &&
        typeof (value as { text?: unknown }).text === "string"
      ) {
        return (value as { text: string }).text;
      }

      if (
        value &&
        typeof value === "object" &&
        "content" in value &&
        typeof (value as { content?: unknown }).content === "string"
      ) {
        return (value as { content: string }).content;
      }

      return undefined;
    };

    const candidateValues = [
      (payload as { choices?: Array<{ message?: { content?: unknown } }> }).choices?.[0]
        ?.message?.content,
      (payload as { output_text?: unknown }).output_text,
      (payload as { choices?: Array<{ text?: unknown }> }).choices?.[0]?.text,
      (payload as { outputs?: Array<{ text?: unknown; content?: unknown }> }).outputs?.[0]
        ?.text,
      (payload as { outputs?: Array<{ text?: unknown; content?: unknown }> }).outputs?.[0]
        ?.content,
      (payload as { content?: unknown }).content,
      (payload as { message?: { content?: unknown } }).message?.content,
      (payload as { response?: { text?: unknown } }).response?.text,
    ];

    if (this.shouldUseLMStudioEndpoint()) {
      const lmCandidate = (payload as { output?: { choices?: any[] } }).output;
      if (Array.isArray(lmCandidate) && lmCandidate.length > 0) {
        const first = lmCandidate[0];
        if (typeof first?.text === "string") return first.text;
        if (typeof first?.content === "string") return first.content;
        if (typeof first?.content?.[0]?.text === "string") return first.content[0].text;
      }

      const maybeMessage = (payload as { message?: unknown }).message;
      if (
        maybeMessage &&
        typeof maybeMessage === "object" &&
        typeof (maybeMessage as { content?: unknown }).content === "string"
      ) {
        return (maybeMessage as { content: string }).content;
      }
    }

    for (const candidate of candidateValues) {
          const text = toText(candidate);
          if (typeof text === "string") {
            // Post-process to remove reasoning tags like <think>...</think>
            return text.replace(/<think>[\s\S]*?<\/think>/gi, "").trim();
          }
        }
      
        return undefined;
      }
  async rewrite(input: HumanizeInput): Promise<ProviderResult> {
    const startedAt = Date.now();

    if (!input.text?.trim()) {
      throw new ProviderError("INVALID_INPUT", "Input text is required");
    }

    const options = input.options ?? {};
    if (this.endpoint) {
      const rewritten = await this.callLocalModel(input.text, {
        tone: options.tone ?? "natural",
        preserveMeaning: options.preserveMeaning ?? true,
        maxTokens: options.maxTokens,
      });

      return {
        text: rewritten,
        provider: this.id,
        latencyMs: Date.now() - startedAt,
        warnings: [],
      };
    }

    const result = applyDeterministicRewrite(input.text);

    return {
      text: result.text,
      provider: this.id,
      latencyMs: Date.now() - startedAt,
      warnings: result.appliedRules.map(
        (ruleId) => `Applied deterministic rule: ${ruleId}`,
      ),
    };
  }

  isAvailable(): boolean {
    return true;
  }
}
