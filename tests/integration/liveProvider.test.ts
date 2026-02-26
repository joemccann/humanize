import { strict as assert } from "node:assert";
import { test } from "node:test";

import { createHumanizeService } from "../../src/service/humanizeService";
import { warOf1812Copy } from "../fixtures/humanizeTestCopies";

const runLiveProviderTests = process.env.HUMANIZE_LIVE_PROVIDER_TESTS === "1";

function parseOptionalInteger(value: string | undefined): number | undefined {
  if (!value) {
    return undefined;
  }
  const parsed = Number.parseInt(value, 10);
  return Number.isNaN(parsed) || parsed <= 0 ? undefined : parsed;
}

test("calls local model backend when LOCAL_LLM_ENDPOINT is set", {
  skip: !runLiveProviderTests || !process.env.LOCAL_LLM_ENDPOINT,
}, async () => {
  const service = createHumanizeService({
    providerConfig: {
      local: {
        endpoint: process.env.LOCAL_LLM_ENDPOINT,
        model: process.env.LOCAL_LLM_MODEL,
        apiKey: process.env.LOCAL_LLM_API_KEY,
        requestTimeoutMs: parseOptionalInteger(process.env.LOCAL_LLM_REQUEST_TIMEOUT_MS),
        systemPromptPath: process.env.LOCAL_LLM_SYSTEM_PROMPT_PATH,
      },
    },
    providerOrder: ["local"],
  });

  const result = await service({
    text: warOf1812Copy,
    provider: "local",
  });

  assert.equal(result.provider.id, "local");
  assert.ok(result.text.length > 100, "expected rewritten output");
  assert.ok(result.text.includes("War of 1812"), "expected subject preserved");
  assert.equal(result.warnings.length, 0, "local LLM path should not emit local-rule warnings");
});

test("calls OpenAI when OPENAI_API_KEY is set", {
  skip: !runLiveProviderTests || !process.env.OPENAI_API_KEY,
}, async () => {
  const service = createHumanizeService({
    providerConfig: {
      openai: {
        apiKey: process.env.OPENAI_API_KEY,
        model: process.env.OPENAI_MODEL,
        endpoint: process.env.OPENAI_ENDPOINT,
        requestTimeoutMs: parseOptionalInteger(process.env.OPENAI_REQUEST_TIMEOUT_MS),
        retryAttempts: parseOptionalInteger(process.env.OPENAI_RETRY_ATTEMPTS),
        maxInputLength: parseOptionalInteger(process.env.OPENAI_MAX_INPUT_LENGTH),
      },
      local: {},
    },
    providerOrder: ["openai", "local"],
  });

  const result = await service({
    text: warOf1812Copy,
    provider: "openai",
  });

  assert.equal(result.provider.id, "openai");
  assert.ok(result.text.length > 100, "expected rewritten output");
  assert.ok(result.text.includes("The War of 1812"));
});

test("calls Anthropic when ANTHROPIC_API_KEY is set", {
  skip: !runLiveProviderTests || !process.env.ANTHROPIC_API_KEY,
}, async () => {
  const service = createHumanizeService({
    providerConfig: {
      anthropic: {
        apiKey: process.env.ANTHROPIC_API_KEY,
        model: process.env.ANTHROPIC_MODEL,
        endpoint: process.env.ANTHROPIC_ENDPOINT,
        requestTimeoutMs: parseOptionalInteger(process.env.ANTHROPIC_REQUEST_TIMEOUT_MS),
      },
      local: {},
    },
    providerOrder: ["anthropic", "local"],
  });

  const result = await service({
    text: warOf1812Copy,
    provider: "anthropic",
  });

  assert.equal(result.provider.id, "anthropic");
  assert.ok(result.text.length > 100, "expected rewritten output");
  assert.ok(result.text.includes("The War of 1812"));
});
