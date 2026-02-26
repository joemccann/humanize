import { createServer, IncomingMessage, ServerResponse } from "node:http";
import { promises as fs } from "node:fs";
import { AddressInfo } from "node:net";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { createHumanizeService, HumanizeService } from "./service/humanizeService";
import { HumanizeInput, ProviderError, ProviderId } from "./providers/types";

type JsonBody = Record<string, unknown>;
type HumanizeApiBody = HumanizeInput & {
  openaiApiKey?: string;
  anthropicApiKey?: string;
};

type ProviderOrder = ProviderId[];

export interface HumanizeServerOptions {
  port?: number;
  service?: ReturnType<typeof createHumanizeService>;
  providerOrder?: ProviderOrder;
}

export interface HumanizeServerInstance {
  server: ReturnType<typeof createServer>;
  close: () => Promise<void>;
  address: () => AddressInfo;
}

const DEFAULT_PORT = 3_000;
const DEFAULT_MAX_INPUT_LENGTH = 8_000;
const LOCAL_STARTUP_CHECK_MS = 1_500;
const DEFAULT_LOCAL_LLM_ENDPOINT = "http://localhost:1234";
const STARTUP_PROVIDER_ORDER_WITH_LOCAL: ProviderId[] = [
  "local",
  "openai",
  "anthropic",
];
const STARTUP_PROVIDER_ORDER_WITHOUT_LOCAL: ProviderId[] = [
  "openai",
  "anthropic",
  "local",
];
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const publicDir = path.join(__dirname, "..", "public");

const jsonHeaders = { "Content-Type": "application/json; charset=utf-8" };
const routeContentType: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
};

function parseOptionalInteger(value?: string): number | undefined {
  if (!value) {
    return undefined;
  }
  const parsed = Number.parseInt(value, 10);
  return Number.isNaN(parsed) || parsed <= 0 ? undefined : parsed;
}

function parseLocalApiFlavor(
  value: string | undefined,
): "auto" | "openai" | "lmstudio" {
  if (value === "openai" || value === "lmstudio") {
    return value;
  }
  return "auto";
}

function parseModelListCandidates(
  endpoint: string,
  apiFlavor: "auto" | "openai" | "lmstudio",
): string[] {
  const trimmed = endpoint.trim().replace(/\/$/, "");
  const candidates = new Set<string>();
  const push = (value: string | undefined) => {
    const normalized = value?.trim().replace(/\/$/, "");
    if (!normalized) {
      return;
    }
    candidates.add(normalized);
  };

  if (trimmed.endsWith("/v1/chat/completions")) {
    push(trimmed.replace(/\/v1\/chat\/completions$/, "/v1/models"));
  }
  if (trimmed.endsWith("/v1/chat")) {
    push(trimmed.replace(/\/v1\/chat$/, "/v1/models"));
  }
  if (trimmed.endsWith("/api/v1/chat")) {
    push(trimmed.replace(/\/api\/v1\/chat$/, "/api/v1/models"));
  }
  if (trimmed.endsWith("/v1")) {
    push(`${trimmed}/models`);
  }
  if (trimmed.endsWith("/api/v1")) {
    push(`${trimmed}/models`);
  }

  if (apiFlavor === "openai") {
    push(`${trimmed}/models`);
  } else if (apiFlavor === "lmstudio") {
    push(`${trimmed}/api/v1/models`);
  } else {
    push(`${trimmed}/api/v1/models`);
    push(`${trimmed}/v1/models`);
  }

  return [...candidates];
}

function extractModelIds(payload: unknown): string[] {
  if (!payload) {
    return [];
  }
  if (Array.isArray(payload)) {
    return payload.reduce<string[]>((ids, item) => {
      if (typeof item === "string") {
        ids.push(item);
        return ids;
      }

      if (item && typeof item === "object" && "id" in item) {
        const id = (item as { id?: unknown }).id;
        if (typeof id === "string") {
          ids.push(id);
        }
      }
      return ids;
    }, []);
  }

  if (typeof payload !== "object") {
    return [];
  }

  const record = payload as Record<string, unknown>;
  const listContainer = Array.isArray(record.data)
    ? record.data
    : Array.isArray(record.models)
      ? record.models
      : [];

  if (!Array.isArray(listContainer)) {
    return [];
  }

  return listContainer.reduce<string[]>((ids, item) => {
    if (typeof item === "string") {
      ids.push(item);
      return ids;
    }
    if (item && typeof item === "object" && "id" in item) {
      const id = (item as { id?: unknown }).id;
      if (typeof id === "string") {
        ids.push(id);
      }
    }
    return ids;
  }, []);
}

function modelListContains(modelList: string[], target?: string): boolean {
  if (!target) {
    return modelList.length > 0;
  }

  const normalizedTarget = target.trim().toLowerCase();
  if (!normalizedTarget) {
    return modelList.length > 0;
  }

  return modelList.some((id) => {
    const normalizedModel = id.trim().toLowerCase();
    return (
      Boolean(normalizedModel) &&
      (normalizedModel === normalizedTarget ||
        normalizedModel.includes(normalizedTarget) ||
        normalizedTarget.includes(normalizedModel))
    );
  });
}

async function isLocalModelAvailable(config: {
  endpoint?: string;
  model?: string;
  apiKey?: string;
  apiFlavor: "auto" | "openai" | "lmstudio";
  requestTimeoutMs?: number;
}): Promise<boolean> {
  if (!config.endpoint) {
    return false;
  }

  const timeoutMs = config.requestTimeoutMs ?? LOCAL_STARTUP_CHECK_MS;
  const modelEndpoints = parseModelListCandidates(config.endpoint, config.apiFlavor);

  for (const modelEndpoint of modelEndpoints) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);

    try {
      const response = await fetch(modelEndpoint, {
        method: "GET",
        headers: {
          ...(config.apiKey ? { Authorization: `Bearer ${config.apiKey}` } : {}),
        },
        signal: controller.signal,
      });

      if (!response.ok) {
        continue;
      }

      const payload = await response.json();
      const models = extractModelIds(payload);
      if (modelListContains(models, config.model)) {
        return true;
      }
    } catch (_error) {
      continue;
    } finally {
      clearTimeout(timeout);
    }
  }

  return false;
}

function resolveStartupProviderOrder(isLocalAvailable: boolean): ProviderOrder {
  return isLocalAvailable
    ? [...STARTUP_PROVIDER_ORDER_WITH_LOCAL]
    : [...STARTUP_PROVIDER_ORDER_WITHOUT_LOCAL];
}

function createDefaultService(
  providerOrder: ProviderOrder = [...STARTUP_PROVIDER_ORDER_WITHOUT_LOCAL],
): HumanizeService {
  return createServiceFromBody({}, providerOrder);
}

function createServiceFromBody(
  body: HumanizeApiBody = {},
  providerOrder: ProviderOrder = [...STARTUP_PROVIDER_ORDER_WITHOUT_LOCAL],
): HumanizeService {
  return createHumanizeService({
    providerConfig: {
      openai: {
        apiKey: body.openaiApiKey ?? process.env.OPENAI_API_KEY,
        model: process.env.OPENAI_MODEL,
        endpoint: process.env.OPENAI_ENDPOINT,
        requestTimeoutMs: parseOptionalInteger(process.env.OPENAI_REQUEST_TIMEOUT_MS),
        retryAttempts: parseOptionalInteger(process.env.OPENAI_RETRY_ATTEMPTS),
        maxInputLength: parseOptionalInteger(process.env.OPENAI_MAX_INPUT_LENGTH),
      },
      anthropic: {
        apiKey: body.anthropicApiKey ?? process.env.ANTHROPIC_API_KEY,
        model: process.env.ANTHROPIC_MODEL,
        endpoint: process.env.ANTHROPIC_ENDPOINT,
        requestTimeoutMs: parseOptionalInteger(
          process.env.ANTHROPIC_REQUEST_TIMEOUT_MS,
        ),
      },
      local: {
        endpoint:
          process.env.LOCAL_LLM_ENDPOINT?.trim() || DEFAULT_LOCAL_LLM_ENDPOINT,
        model: process.env.LOCAL_LLM_MODEL,
        apiKey: process.env.LOCAL_LLM_API_KEY,
        apiFlavor: parseLocalApiFlavor(process.env.LOCAL_LLM_API_FLAVOR),
        requestTimeoutMs: parseOptionalInteger(process.env.LOCAL_LLM_REQUEST_TIMEOUT_MS),
        systemPromptPath: process.env.LOCAL_LLM_SYSTEM_PROMPT_PATH,
      },
    },
    maxInputLength: parseOptionalInteger(process.env.HUMANIZE_MAX_INPUT_LENGTH) ?? DEFAULT_MAX_INPUT_LENGTH,
    promptVersion: process.env.HUMANIZE_PROMPT_VERSION ?? "humanizer-system-prompt:v1",
    providerOrder,
  });
}

export function createHumanizeHttpServer(options: HumanizeServerOptions = {}) {
  const service: HumanizeService | undefined = options.service;
  const providerOrder: ProviderOrder = options.providerOrder?.length
    ? [...options.providerOrder]
    : [...STARTUP_PROVIDER_ORDER_WITHOUT_LOCAL];
  const defaultProvider = providerOrder[0] ?? "local";

  return createServer(async (req, res) => {
    if (!req.url || !req.method) {
      sendErrorResponse(res, 400, "INVALID_REQUEST", "Request missing required fields");
      return;
    }

    if (req.url === "/api/humanize" && req.method.toUpperCase() === "POST") {
      try {
        const rawBody = await parseJsonBody(req);
        const body = rawBody as HumanizeApiBody;
        const { openaiApiKey, anthropicApiKey, ...apiBody } = body;
        const activeService =
          service ??
          createServiceFromBody({
            openaiApiKey,
            anthropicApiKey,
          }, providerOrder);
        const output = await activeService(apiBody as HumanizeInput);
        sendJson(res, 200, output);
      } catch (error) {
        const mapped = mapErrorToHttp(error);
        sendErrorResponse(res, mapped.status, mapped.code, mapped.message, mapped.details);
      }
      return;
    }

    if (req.url === "/api/provider-order" && req.method.toUpperCase() === "GET") {
      sendJson(res, 200, {
        providerOrder,
        defaultProvider,
      });
      return;
    }

    if (req.method.toUpperCase() === "GET") {
      const pathname = new URL(req.url, "http://localhost").pathname;
      if (pathname === "/" || pathname.startsWith("/index")) {
        await serveStatic(res, path.join(publicDir, "index.html"));
        return;
      }

      if (
        pathname.startsWith("/assets/") ||
        pathname.startsWith("/styles") ||
        pathname.startsWith("/app")
      ) {
        const requestedPath = path.join(publicDir, pathname.replace(/^\//, ""));
        await serveStatic(res, requestedPath);
        return;
      }
    }

    sendErrorResponse(res, 404, "NOT_FOUND", "Not found");
  });
}

export async function startHumanizeServer(options: HumanizeServerOptions = {}): Promise<HumanizeServerInstance> {
  const localEndpoint =
    process.env.LOCAL_LLM_ENDPOINT?.trim() || DEFAULT_LOCAL_LLM_ENDPOINT;
  const localModelConfig = {
    endpoint: localEndpoint,
    model: process.env.LOCAL_LLM_MODEL,
    apiKey: process.env.LOCAL_LLM_API_KEY,
    apiFlavor: parseLocalApiFlavor(process.env.LOCAL_LLM_API_FLAVOR),
    requestTimeoutMs: Math.min(
      parseOptionalInteger(process.env.LOCAL_LLM_REQUEST_TIMEOUT_MS) ??
        LOCAL_STARTUP_CHECK_MS,
      LOCAL_STARTUP_CHECK_MS,
    ),
  };
  const isLocalModelUp = await isLocalModelAvailable(localModelConfig);
  const startupProviderOrder = resolveStartupProviderOrder(isLocalModelUp);

  console.log(
    `Local model availability check (${localEndpoint}): ${
      isLocalModelUp ? "available" : "unavailable"
    }`,
  );

  const port = options.port ?? Number(process.env.PORT ?? DEFAULT_PORT);
  const server = createHumanizeHttpServer({
    ...options,
    providerOrder: startupProviderOrder,
  });

  await new Promise<void>((resolve, reject) => {
    server.listen(port, () => {
      resolve();
    });
    server.once("error", reject);
  });

  return {
    server,
    close: () => {
      return new Promise<void>((resolve, reject) => {
        server.close((error) => {
          if (error) {
            reject(error);
            return;
          }
          resolve();
        });
      });
    },
    address: () => {
      const address = server.address();
      if (!address || typeof address === "string") {
        throw new Error("Failed to read server address");
      }
      return address;
    },
  };
}

export async function startServer(options: HumanizeServerOptions = {}): Promise<void> {
  const server = await startHumanizeServer(options);
  const address = server.address();
  const host = address.address === "::" ? "localhost" : address.address;
  console.log(`Humanize server running at http://${host}:${address.port}`);
}

export async function parseJsonBody(req: IncomingMessage): Promise<JsonBody> {
  const chunks: string[] = [];
  return new Promise((resolve, reject) => {
    req.on("data", (chunk) => {
      chunks.push(Buffer.isBuffer(chunk) ? chunk.toString("utf8") : `${chunk}`);
    });
    req.on("end", () => {
      try {
        const text = chunks.join("");
        const payload = text ? JSON.parse(text) : {};
        resolve(payload);
      } catch (error) {
        reject(error);
      }
    });
    req.on("error", reject);
  });
}

async function serveStatic(res: ServerResponse, filePath: string): Promise<void> {
  const normalized = path.normalize(filePath);
  if (!normalized.startsWith(publicDir)) {
    sendErrorResponse(res, 403, "FORBIDDEN", "Invalid path");
    return;
  }

  try {
    const data = await fs.readFile(normalized);
    const ext = path.extname(normalized);
    const contentType = routeContentType[ext] ?? "application/octet-stream";
    res.writeHead(200, { "Content-Type": contentType });
    res.end(data);
  } catch (_err) {
    sendErrorResponse(res, 404, "NOT_FOUND", "Asset not found");
  }
}

function sendJson(res: ServerResponse, status: number, payload: unknown): void {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    ...jsonHeaders,
    "Content-Length": Buffer.byteLength(body),
  });
  res.end(body);
}

export function sendErrorResponse(
  res: ServerResponse,
  status: number,
  code: string,
  message: string,
  details?: Record<string, unknown>,
): void {
  sendJson(res, status, {
    error: {
      code,
      message,
      details,
    },
  });
}

export function mapErrorToHttp(error: unknown): {
  status: number;
  code: string;
  message: string;
  details?: Record<string, unknown>;
} {
  if (error instanceof SyntaxError) {
    return { status: 400, code: "INVALID_INPUT", message: "Invalid JSON body" };
  }

  if (error instanceof ProviderError) {
    const details = error.details;
    switch (error.code) {
      case "INVALID_INPUT":
        return { status: 400, code: error.code, message: error.message, details };
      case "PAYLOAD_TOO_LARGE":
        return { status: 413, code: error.code, message: error.message, details };
      case "PROVIDER_MISCONFIGURED":
        return { status: 422, code: error.code, message: error.message, details };
      case "TIMEOUT":
        return { status: 408, code: error.code, message: error.message, details };
      case "PROVIDER_FAILED":
      case "INTERNAL_ERROR":
      default:
        return { status: 500, code: error.code, message: error.message, details };
    }
  }

  return {
    status: 500,
    code: "INTERNAL_ERROR",
    message: "Unexpected server error",
  };
}

if (import.meta.main) {
  startServer().catch((error) => {
    console.error("Failed to start server", error);
    process.exitCode = 1;
  });
}
