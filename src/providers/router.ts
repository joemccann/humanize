import {
  OpenAIProvider,
  OpenAIProviderConfig,
} from "./openai";
import {
  AnthropicProvider,
  AnthropicProviderConfig,
} from "./anthropic";
import { LocalProvider } from "./local";
import {
  HumanizeInput,
  ProviderError,
  ProviderId,
  LocalProviderConfig,
  RewriteProvider,
} from "./types";

export type ProviderConfig = {
  openai?: OpenAIProviderConfig;
  anthropic?: AnthropicProviderConfig;
  local?: LocalProviderConfig;
};

export const DEFAULT_PROVIDER_ORDER: ProviderId[] = [
  "openai",
  "anthropic",
  "local",
];

export interface ProviderRouter {
  readonly providers: Record<ProviderId, RewriteProvider>;
  readonly order: ProviderId[];
  select(input: HumanizeInput): RewriteProvider;
  getProvider(id: ProviderId): RewriteProvider;
  rewrite(input: HumanizeInput): Promise<{
    text: string;
    provider: ProviderId;
    model?: string;
    latencyMs: number;
    warnings: string[];
  }>;
}

export function createProviderRegistry(
  config: ProviderConfig = {},
  order: ProviderId[] = [...DEFAULT_PROVIDER_ORDER],
): ProviderRouter {
  const providers: Record<ProviderId, RewriteProvider> = {
    openai: new OpenAIProvider(config.openai),
    anthropic: new AnthropicProvider(config.anthropic),
    local: new LocalProvider(config.local),
  };

  function select(input: HumanizeInput): RewriteProvider {
    if (input.provider && input.provider !== "auto") {
      const provider = providers[input.provider];
      if (!provider.isAvailable()) {
        throw new ProviderError(
          "PROVIDER_MISCONFIGURED",
          `${input.provider} provider is not available`,
        );
      }
      return provider;
    }

    for (const providerId of order) {
      const provider = providers[providerId];
      if (provider.isAvailable()) {
        return provider;
      }
    }

    return providers.local;
  }

  return {
    providers,
    order: [...order],
    select,
    getProvider(id: ProviderId): RewriteProvider {
      return providers[id];
    },
    async rewrite(input: HumanizeInput) {
      const provider = select(input);
      return provider.rewrite(input);
    },
  };
}
