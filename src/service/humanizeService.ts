import { HumanizeInput, HumanizeOptions, ProviderError, ProviderId } from "../providers/types";
import { applyDeterministicRewrite, buildRewriteDiff } from "../core/deterministicRewrite";
import {
  createProviderRegistry,
  ProviderConfig,
  ProviderRouter,
} from "../providers/router";

const DEFAULT_PROMPT_VERSION = "humanizer-system-prompt:v1";
const DEFAULT_MAX_INPUT_LENGTH = 8_000;

export interface HumanizeServiceConfig {
  providerConfig?: ProviderConfig;
  providerOrder?: ReadonlyArray<ProviderId>;
  maxInputLength?: number;
  promptVersion?: string;
}

export interface HumanizeServiceResult {
  text: string;
  provider: {
    id: ProviderId;
    model?: string;
  };
  timings: {
    totalMs: number;
    providerMs: number;
    localMs: number;
  };
  warnings: string[];
  stats: {
    inputLength: number;
    outputLength: number;
    editsEstimated: number;
  };
  promptVersion: string;
  systemPromptUsed: boolean;
}

export type HumanizeService = (input: HumanizeInput) => Promise<HumanizeServiceResult>;

export interface HumanizeRuntimeResult {
  result: {
    text: string;
    provider: ProviderId;
    model?: string;
    warnings: string[];
  };
  providerMs: number;
}

function ensureNumber(input: unknown, message: string): number | undefined {
  if (input === undefined) {
    return undefined;
  }

  if (typeof input !== "number" || !Number.isInteger(input) || input <= 0) {
    throw new ProviderError("INVALID_INPUT", message);
  }

  return input;
}

function normalizeInput(input: HumanizeInput, maxInputLength: number): {
  text: string;
  options: HumanizeOptions;
  provider: HumanizeInput["provider"];
} {
  if (!input || typeof input !== "object") {
    throw new ProviderError("INVALID_INPUT", "Input payload is required");
  }

  if (!input.text || typeof input.text !== "string") {
    throw new ProviderError("INVALID_INPUT", "Input text is required");
  }

  const text = input.text.trim();
  if (!text) {
    throw new ProviderError("INVALID_INPUT", "Input text cannot be empty");
  }

  if (text.length > maxInputLength) {
    throw new ProviderError(
      "PAYLOAD_TOO_LARGE",
      `Input text exceeds max length of ${maxInputLength}`,
    );
  }

  const options = input.options ?? {};
  if (options.tone !== undefined && !["natural", "casual", "professional"].includes(options.tone)) {
    throw new ProviderError("INVALID_INPUT", "Invalid tone option");
  }

  if (options.preserveMeaning !== undefined && typeof options.preserveMeaning !== "boolean") {
    throw new ProviderError("INVALID_INPUT", "preserveMeaning must be boolean");
  }

  if (options.maxTokens !== undefined && !Number.isInteger(options.maxTokens)) {
    throw new ProviderError("INVALID_INPUT", "maxTokens must be an integer");
  }

  return {
    text,
    options: {
      tone: options.tone ?? "natural",
      preserveMeaning: options.preserveMeaning ?? true,
      maxTokens: ensureNumber(
        options.maxTokens,
        "maxTokens must be a positive integer",
      ),
    },
    provider: input.provider ?? "auto",
  };
}

function estimateEdits(before: string, after: string): number {
  const diff = buildRewriteDiff(before, after);
  if (!diff.changed) {
    return 0;
  }

  return diff.segments.reduce((count, segment) => {
    if (segment.type !== "replace") {
      return count;
    }
    return count + 1;
  }, 0);
}

async function runProviderWithFallback(
  router: ProviderRouter,
  normalized: HumanizeInput,
): Promise<HumanizeRuntimeResult> {
  const requestedProvider = normalized.provider ?? "auto";
  const providerIds =
    requestedProvider === "auto" ? router.order : [requestedProvider];
  let lastFailure: unknown;

  if (requestedProvider !== "auto" && !router.getProvider(requestedProvider).isAvailable()) {
    throw new ProviderError(
      "PROVIDER_MISCONFIGURED",
      `${requestedProvider} provider is not available`,
    );
  }

  for (const providerId of providerIds) {
    const provider = router.getProvider(providerId);
    if (!provider.isAvailable()) {
      continue;
    }

    const providerStart = Date.now();
    try {
      const result = await provider.rewrite(normalized);
      return {
        result: { ...result },
        providerMs: Date.now() - providerStart,
      };
    } catch (error) {
      lastFailure = error;
      if (requestedProvider !== "auto" || providerId === "local") {
        throw error;
      }
    }
  }

  if (lastFailure instanceof Error) {
    throw new ProviderError(
      "PROVIDER_FAILED",
      "All providers failed after fallback attempts",
      { details: { source: lastFailure.message } },
    );
  }

  throw new ProviderError(
    "PROVIDER_FAILED",
    "All providers failed after fallback attempts",
  );
}

export function createHumanizeService(config: HumanizeServiceConfig = {}): HumanizeService {
  const maxInputLength = config.maxInputLength ?? DEFAULT_MAX_INPUT_LENGTH;
  const promptVersion = config.promptVersion ?? DEFAULT_PROMPT_VERSION;
  const providerOrder = config.providerOrder ? [...config.providerOrder] : undefined;
  const router = createProviderRegistry(config.providerConfig ?? {}, providerOrder);

  return async function humanize(input: HumanizeInput): Promise<HumanizeServiceResult> {
    const startedAt = Date.now();
    const { text, options, provider } = normalizeInput(input, maxInputLength);

    const localStart = Date.now();
    const prepass = applyDeterministicRewrite(text);
    const localMs = Date.now() - localStart;

    const normalizedInput: HumanizeInput = {
      ...input,
      text: prepass.text,
      options,
      provider,
    };

    const runtime = await runProviderWithFallback(router, normalizedInput);
    const output = runtime.result;
    const elapsedMs = Date.now() - startedAt;
    const diffCount = estimateEdits(text, output.text);

    return {
      text: output.text,
      provider: {
        id: output.provider,
        model: output.model,
      },
      timings: {
        totalMs: elapsedMs,
        providerMs: runtime.providerMs,
        localMs,
      },
      warnings: [
        ...prepass.appliedRules.map((ruleId) => `local-rule:${ruleId}`),
        ...output.warnings,
      ],
      stats: {
        inputLength: text.length,
        outputLength: output.text.length,
        editsEstimated: diffCount,
      },
      promptVersion,
      systemPromptUsed: output.provider !== "local",
    };
  };
}
