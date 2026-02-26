import { strict as assert } from "node:assert";
import { AddressInfo } from "node:net";
import { describe, test } from "node:test";

import { createHumanizeHttpServer } from "../../src/server";
import { HumanizeService } from "../../src/service/humanizeService";
import { ProviderError } from "../../src/providers/types";

const sampleOutput = {
  text: "clean text",
  provider: {
    id: "local" as const,
    model: "local-v1",
  },
  timings: {
    totalMs: 12,
    providerMs: 10,
    localMs: 2,
  },
  warnings: ["local-rule:test"],
  stats: {
    inputLength: 12,
    outputLength: 9,
    editsEstimated: 1,
  },
  promptVersion: "humanizer-system-prompt:v1",
  systemPromptUsed: false,
};

const defaultService: HumanizeService = async (_input) => sampleOutput;

async function withServer(
  fn: (baseUrl: string) => Promise<void>,
  service: HumanizeService = defaultService,
): Promise<void> {
  const app = createHumanizeHttpServer({ service });

  await new Promise<void>((resolve, reject) => {
    app.listen(0, resolve);
    app.once("error", reject);
  });

  const address = app.address();
  if (!address || typeof address === "string") {
    throw new Error("Server did not provide socket address");
  }

  const { port } = address as AddressInfo;
  const baseUrl = `http://127.0.0.1:${port}`;

  try {
    await fn(baseUrl);
  } finally {
    await new Promise<void>((resolve, reject) => {
      app.close((error) => {
        if (error) {
          reject(error);
          return;
        }
        resolve();
      });
    });
  }
}

describe("POST /api/humanize", () => {
  test("returns rewritten text from service", async () => {
    await withServer(async (baseUrl) => {
      const response = await fetch(`${baseUrl}/api/humanize`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ text: "sample input" }),
      });

      const payload = await response.json();

      assert.equal(response.status, 200);
      assert.equal(payload.text, sampleOutput.text);
      assert.equal(payload.provider.id, sampleOutput.provider.id);
    });
  });

  test("maps invalid JSON body to 400", async () => {
    await withServer(async (baseUrl) => {
      const response = await fetch(`${baseUrl}/api/humanize`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: "not-json",
      });

      const payload = await response.json();

      assert.equal(response.status, 400);
      assert.equal(payload.error.code, "INVALID_INPUT");
      assert.equal(payload.error.message, "Invalid JSON body");
    });
  });

  test("maps service errors to contract response", async () => {
    const failingService: HumanizeService = async (_input) => {
      throw new ProviderError("INVALID_INPUT", "Payload rejected");
    };

    await withServer(
      async (baseUrl) => {
        const response = await fetch(`${baseUrl}/api/humanize`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ text: "bad" }),
        });

        const payload = await response.json();

        assert.equal(response.status, 400);
        assert.equal(payload.error.code, "INVALID_INPUT");
        assert.equal(payload.error.message, "Payload rejected");
      },
      failingService,
    );
  });
});

describe("GET static routes", () => {
  test("returns startup provider order", async () => {
    await withServer(async (baseUrl) => {
      const response = await fetch(`${baseUrl}/api/provider-order`);
      const payload = await response.json();

      assert.equal(response.status, 200);
      assert.ok(Array.isArray(payload.providerOrder));
      assert.equal(typeof payload.defaultProvider, "string");
      assert.equal(payload.providerOrder.includes(payload.defaultProvider), true);
    });
  });

  test("returns ui index page", async () => {
    await withServer(async (baseUrl) => {
      const response = await fetch(`${baseUrl}/`);
      const body = await response.text();

      assert.equal(response.status, 200);
      assert.equal(response.headers.get("content-type"), "text/html; charset=utf-8");
      assert.match(body, /<title>Humanize<\/title>/);
    });
  });

  test("returns 404 for unknown route", async () => {
    await withServer(async (baseUrl) => {
      const response = await fetch(`${baseUrl}/does-not-exist`);
      const body = await response.json();

      assert.equal(response.status, 404);
      assert.equal(body.error.code, "NOT_FOUND");
    });
  });
});
