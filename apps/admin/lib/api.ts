"use client";
import { createAdminClient, type Schemas } from "@news/api-client/admin";

export type Session = Schemas["SessionInfo"];
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    readonly detail: string,
    readonly extra: Record<string, unknown> = {},
  ) {
    super(detail);
  }
  /** Server validation messages by field, whichever of the two shapes they arrive in. */
  get fields(): Record<string, string> {
    const { errors } = this.extra;
    if (Array.isArray(errors)) return Object.fromEntries(errors.map((e) => [e.field, e.message]));
    if (errors && typeof errors === "object")
      return Object.fromEntries(Object.entries(errors).map(([k, v]) => [k, [v].flat().join(" ")]));
    return {};
  }
}

// The CSRF token lives in memory only: it is derived from the session and refetched with it.
let csrf = "";
export const setCsrf = (token: string) => {
  csrf = token;
};

export const client = createAdminClient({ baseUrl: "", credentials: "same-origin" });
client.use({
  onRequest: ({ request }) => {
    if (csrf && !["GET", "HEAD"].includes(request.method)) request.headers.set("X-CSRF-Token", csrf);
    return request;
  },
});

let stepUp: (() => Promise<boolean>) | null = null;
export const onStepUp = (handler: typeof stepUp) => {
  stepUp = handler;
};
let onSignedOut: (() => void) | null = null;
export const onUnauthenticated = (handler: typeof onSignedOut) => {
  onSignedOut = handler;
};

async function refreshCsrf(): Promise<boolean> {
  const { data } = await client.GET("/api/v1/auth/session");
  if (data) setCsrf(data.csrf_token);
  return Boolean(data);
}

type Result<T> = { data?: T; error?: unknown; response: Response };

function toError(result: Result<unknown>): ApiError {
  const body = (result.error ?? {}) as Record<string, unknown>;
  const { code, detail, ...extra } = body;
  return new ApiError(result.response.status, String(code ?? "unavailable"), String(detail ?? ""), extra);
}

/** Runs a request; if the server wants a fresh MFA check, asks for it and resumes the same action. */
export async function call<T>(run: () => Promise<Result<T>>): Promise<T> {
  const attempt = async () => {
    try {
      return await run();
    } catch {
      throw new ApiError(0, "offline", "");
    }
  };
  let result = await attempt();
  if (result.response.ok) return result.data as T;
  let error = toError(result);
  // Clicked before the session loaded, or it was renewed in another tab: refresh the token once and resume.
  if (error.code === "csrf_failed" && (await refreshCsrf())) {
    result = await attempt();
    if (result.response.ok) return result.data as T;
    error = toError(result);
  }
  if (error.code === "step_up_required" && stepUp && (await stepUp())) {
    result = await attempt();
    if (result.response.ok) return result.data as T;
    error = toError(result);
  }
  if (error.status === 401 && ["not_authenticated", "authentication_failed"].includes(error.code))
    onSignedOut?.();
  throw error;
}
