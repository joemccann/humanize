import { promises as fs } from "node:fs";
import * as path from "node:path";

import {
  HumanizeInput,
  HumanizeOptions,
  ProviderError,
  RewriteProvider,
} from "./types";

type RetryPolicy = {
  maxAttempts: number;
  initialDelayMs: number;
  maxDelayMs: number;
  exponentialBase: number;
};

export type OpenAIProviderConfig = {
  apiKey?: string;
  model?: string;
  endpoint?: string;
  maxInputLength?: number;
  systemPromptPath?: string;
  requestTimeoutMs?: number;
  retryAttempts?: number;
};

export class OpenAIProvider implements RewriteProvider {
  readonly id = "openai" as const;
  private readonly apiKey?: string;
  private readonly model: string;
  private readonly endpoint: string;
  private readonly maxInputLength: number;
  private readonly systemPromptPath: string;
  private readonly requestTimeoutMs: number;
  private readonly retryAttempts: number;
  private readonly retryPolicy: RetryPolicy;
  private systemPromptCache: string | null = null;

  constructor(config: OpenAIProviderConfig = {}) {
    this.apiKey = config.apiKey;
    this.model = config.model ?? "gpt-4o-mini";
    this.endpoint = config.endpoint ?? "https://api.openai.com/v1/chat/completions";
    this.maxInputLength = config.maxInputLength ?? 8000;
    this.systemPromptPath =
      config.systemPromptPath ??
      path.resolve(process.cwd(), "tasks", "humanizer-system-prompt.md");
    this.requestTimeoutMs = config.requestTimeoutMs ?? 12000;
    this.retryAttempts = config.retryAttempts ?? 2;
    this.retryPolicy = {
      maxAttempts: this.retryAttempts,
      initialDelayMs: 300,
      maxDelayMs: 2_000,
      exponentialBase: 2,
    };
  }

  isAvailable(): boolean {
    return !!this.apiKey;
  }

  async rewrite(input: HumanizeInput) {
    const startedAt = Date.now();
    const normalized = this.validateInput(input);

    if (!this.isAvailable()) {
      throw new ProviderError(
        "PROVIDER_MISCONFIGURED",
        "OpenAI provider has no API key configured",
      );
    }

    const systemPrompt = await this.getSystemPrompt();
    const rewritten = await this.callOpenAI(normalized, systemPrompt);

    return {
      text: rewritten,
      provider: this.id,
      model: this.model,
      latencyMs: Date.now() - startedAt,
      warnings: [],
    };
  }

  private validateInput(input: HumanizeInput): {
    text: string;
    options: HumanizeOptions;
  } {
    if (!input.text || typeof input.text !== "string") {
      throw new ProviderError("INVALID_INPUT", "Input text is required");
    }

    const text = input.text.trim();
    if (!text) {
      throw new ProviderError("INVALID_INPUT", "Input text cannot be empty");
    }

    if (text.length > this.maxInputLength) {
      throw new ProviderError(
        "PAYLOAD_TOO_LARGE",
        `Input text exceeds max length of ${this.maxInputLength}`,
      );
    }

    const options = input.options ?? {};
    if (options.tone !== undefined && !["natural", "casual", "professional"].includes(options.tone)) {
      throw new ProviderError("INVALID_INPUT", "Invalid tone option");
    }

    if (
      options.preserveMeaning !== undefined &&
      typeof options.preserveMeaning !== "boolean"
    ) {
      throw new ProviderError("INVALID_INPUT", "preserveMeaning must be boolean");
    }

    if (
      options.maxTokens !== undefined &&
      (!Number.isInteger(options.maxTokens) || options.maxTokens <= 0)
    ) {
      throw new ProviderError(
        "INVALID_INPUT",
        "maxTokens must be a positive integer",
      );
    }

    return {
      text,
      options: {
        tone: options.tone ?? "natural",
        preserveMeaning: options.preserveMeaning ?? true,
        maxTokens: options.maxTokens,
      },
    };
  }

  private async getSystemPrompt(): Promise<string> {
    if (this.systemPromptCache) {
      return this.systemPromptCache;
    }

    try {
      const prompt = await fs.readFile(this.systemPromptPath, "utf8");
      const normalized = prompt.trim();
      if (!normalized) {
        throw new ProviderError(
          "PROVIDER_MISCONFIGURED",
          `System prompt file is empty: ${this.systemPromptPath}`,
        );
      }
      this.systemPromptCache = normalized;
      return this.systemPromptCache;
    } catch (error) {
      throw new ProviderError(
        "PROVIDER_MISCONFIGURED",
        `Failed to load humanizer system prompt: ${this.systemPromptPath}`,
      );
    }
  }

  private async callOpenAI(
    normalizedInput: { text: string; options: HumanizeOptions },
    systemPrompt: string,
  ): Promise<string> {
    let lastError: unknown;

    for (let attempt = 1; attempt <= this.retryPolicy.maxAttempts; attempt += 1) {
      try {
        return await this.callOnce(normalizedInput, systemPrompt, attempt);
      } catch (error) {
        lastError = error;
        if (attempt >= this.retryPolicy.maxAttempts) {
          break;
        }
        await new Promise((resolve) =>
          setTimeout(
            resolve,
            Math.min(
              this.retryPolicy.maxDelayMs,
              this.retryPolicy.initialDelayMs * this.retryPolicy.exponentialBase ** (attempt - 1),
            ),
          ),
        );
      }
    }

    if (lastError instanceof Error) {
      throw lastError;
    }

    throw new ProviderError(
      "PROVIDER_FAILED",
      "OpenAI request failed after retries",
    );
  }

  private async callOnce(
    input: { text: string; options: HumanizeOptions },
    systemPrompt: string,
    attempt: number,
  ): Promise<string> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.requestTimeoutMs);

    try {
      const response = await fetch(this.endpoint, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          "Content-Type": "application/json",
        },
        signal: controller.signal,
        body: JSON.stringify({
          model: this.model,
          messages: [
            {
              role: "system",
              content: systemPrompt,
            },
            {
              role: "user",
              content: `Rewrite this text:\n\n${input.text}\n\nOptions:\n${JSON.stringify(
                {
                  tone: input.options.tone,
                  preserveMeaning: input.options.preserveMeaning,
                  maxTokens: input.options.maxTokens,
                },
                null,
                2,
              )}`,
            },
          ],
          max_tokens: input.options.maxTokens,
          temperature: 0.3,
        }),
      });

      if (!response.ok) {
        if (response.status === 401) {
          throw new ProviderError(
            "PROVIDER_MISCONFIGURED",
            "OpenAI API key is invalid or has expired",
            { status: 401 },
          );
        }
        throw new ProviderError(
          "PROVIDER_FAILED",
          `OpenAI request failed on attempt ${attempt}`,
          { status: response.status },
        );
      }

      const payload = (await response.json()) as any;
      const rewritten =
        payload?.choices?.[0]?.message?.content ||
        payload?.output_text ||
        payload?.choices?.[0]?.text;

      if (typeof rewritten !== "string" || !rewritten.trim()) {
        throw new ProviderError(
          "PROVIDER_FAILED",
          "OpenAI returned an empty rewritten result",
        );
      }

      return rewritten.trim();
    } catch (error) {
      if (
        (error as Error).name === "AbortError" ||
        (error instanceof Error && error.message.includes("timeout"))
      ) {
        throw new ProviderError("TIMEOUT", "OpenAI request timed out");
      }
      throw error;
    } finally {
      clearTimeout(timeout);
    }
  }
}
