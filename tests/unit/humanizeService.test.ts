import { strict as assert } from "node:assert";
import { test } from "node:test";

import { createHumanizeService } from "../../src/service/humanizeService";
import { ProviderError } from "../../src/providers/types";
import { warOf1812Copy } from "../fixtures/humanizeTestCopies";

test("processes long humanize copy via local provider", async () => {
  const service = createHumanizeService({
    providerOrder: ["local"],
    maxInputLength: 12000,
  });

  const result = await service({
    text: warOf1812Copy,
    provider: "local",
  });

  assert.equal(result.provider.id, "local");
  assert.equal(result.text.includes("The War of 1812"), true);
  assert.equal(result.text.includes("in order to"), false);
  assert.equal(result.warnings.some((warning) => warning.startsWith("local-rule:")), true);
  assert.equal(result.stats.editsEstimated > 0, true);
});

test("falls back to local provider when OpenAI is unavailable", async () => {
  const service = createHumanizeService({
    providerConfig: {
      openai: {},
    },
    providerOrder: ["openai", "local"],
    maxInputLength: 100,
  });

  const result = await service({
    text: "in order to test fallback path",
    provider: "auto",
  });

  assert.equal(result.provider.id, "local");
  assert.equal(result.text, "to test fallback path");
});

test("falls back to local provider when OpenAI request fails", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (..._args: Parameters<typeof fetch>) => {
    throw new Error("Simulated network failure");
  };

  try {
    const service = createHumanizeService({
      providerConfig: {
        openai: {
          apiKey: "x",
          retryAttempts: 1,
        },
      },
      providerOrder: ["openai", "local"],
      maxInputLength: 100,
    });

    const result = await service({
      text: "In order to test the failure path.",
      provider: "auto",
    });

    assert.equal(result.provider.id, "local");
    assert.ok(result.warnings.includes("local-rule:filler-phrases"));
    assert.equal(result.text, "to test the failure path.");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("keeps a rejected payload size error", async () => {
  const service = createHumanizeService({ maxInputLength: 5 });

  await assert.rejects(
    () =>
      service({
        text: "too many characters",
      }),
    (error: unknown) => {
      assert.ok(error instanceof ProviderError);
      assert.equal(error.code, "PAYLOAD_TOO_LARGE");
      return true;
    },
  );
});

test("validates tone option", async () => {
  const service = createHumanizeService({});

  await assert.rejects(
    () =>
      service({
        text: "input",
        options: { tone: "snarky" as unknown as "natural" },
      }),
    (error: unknown) => {
      assert.ok(error instanceof ProviderError);
      assert.equal(error.code, "INVALID_INPUT");
      return true;
    },
  );
});
