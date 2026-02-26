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

export type AnthropicProviderConfig = {
  apiKey?: string;
  model?: string;
  endpoint?: string;
  requestTimeoutMs?: number;
  systemPromptPath?: string;
};

export class AnthropicProvider implements RewriteProvider {
  readonly id = "anthropic" as const;
  private readonly apiKey?: string;
  private readonly model: string;
  private readonly endpoint: string;
  private readonly requestTimeoutMs: number;
  private readonly systemPromptPath: string;
  private readonly retryPolicy: RetryPolicy;
  private systemPromptCache: string | null = null;

  constructor(config: AnthropicProviderConfig = {}) {
    this.apiKey = config.apiKey;
    this.model = config.model ?? "claude-3-haiku-20240307";
    this.endpoint = config.endpoint ?? "https://api.anthropic.com/v1/messages";
    this.requestTimeoutMs = config.requestTimeoutMs ?? 12000;
    this.systemPromptPath =
      config.systemPromptPath ??
      path.resolve(process.cwd(), "tasks", "humanizer-system-prompt.md");
    this.retryPolicy = {
      maxAttempts: 2,
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

    if (!input.text?.trim()) {
      throw new ProviderError("INVALID_INPUT", "Input text is required");
    }

    if (!this.isAvailable()) {
      throw new ProviderError(
        "PROVIDER_MISCONFIGURED",
        "Anthropic provider has no API key configured",
      );
    }

    const normalized = input.text.trim();
    const options = input.options ?? {};
    const rewritten = await this.callAnthropicWithRetry({
      text: normalized,
      options: {
        tone: options.tone ?? "natural",
        preserveMeaning: options.preserveMeaning ?? true,
        maxTokens: options.maxTokens,
      },
    });

    return {
      text: rewritten,
      provider: this.id,
      model: this.model,
      latencyMs: Date.now() - startedAt,
      warnings: [],
    };
  }

  private async callAnthropicWithRetry(
    input: { text: string; options: HumanizeOptions },
  ): Promise<string> {
    let lastError: unknown;

    for (let attempt = 1; attempt <= this.retryPolicy.maxAttempts; attempt += 1) {
      try {
        return await this.callAnthropic(input, attempt);
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

    if (lastError instanceof ProviderError) {
      throw lastError;
    }

    throw new ProviderError(
      "PROVIDER_FAILED",
      "Anthropic request failed after retries",
    );
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
    } catch (_error) {
      throw new ProviderError(
        "PROVIDER_MISCONFIGURED",
        `Failed to load humanizer system prompt: ${this.systemPromptPath}`,
      );
    }
  }

  private async callAnthropic(
    input: { text: string; options: HumanizeOptions },
    attempt: number,
  ): Promise<string> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.requestTimeoutMs);

    try {
      const systemPrompt = await this.getSystemPrompt();
      const response = await fetch(this.endpoint, {
        method: "POST",
        headers: {
          "x-api-key": this.apiKey ?? "",
          "Content-Type": "application/json",
          "anthropic-version": "2023-06-01",
        },
        signal: controller.signal,
        body: JSON.stringify({
          model: this.model,
          system: systemPrompt,
          messages: [
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
          max_tokens: input.options.maxTokens ?? 1024,
        }),
      });

      if (!response.ok) {
        throw new ProviderError(
          "PROVIDER_FAILED",
          `Anthropic request failed on attempt ${attempt}`,
          { status: response.status },
        );
      }

      const payload = (await response.json()) as any;
      const rewritten =
        payload?.content?.[0]?.type === "text"
          ? payload.content[0].text
          : undefined;

      if (typeof rewritten !== "string" || !rewritten.trim()) {
        throw new ProviderError(
          "PROVIDER_FAILED",
          "Anthropic returned an empty rewritten result",
        );
      }

      return rewritten.trim();
    } catch (error) {
      if (error instanceof ProviderError) {
        throw error;
      }
      if (
        (error as Error).name === "AbortError" ||
        (error as Error).message?.includes("timeout")
      ) {
        throw new ProviderError("TIMEOUT", "Anthropic request timed out");
      }
      throw error;
    } finally {
      clearTimeout(timeout);
    }
  }
}
