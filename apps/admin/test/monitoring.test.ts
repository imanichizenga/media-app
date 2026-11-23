import { afterEach, describe, expect, it, vi } from "vitest";
import { ApiError } from "../lib/api";
import { isExpected, redact, scrub } from "../lib/monitoring";
import { forward, parseDsn } from "../lib/tunnel";

const DSN = "https://abc123@o1.ingest.sentry.io/42";
let clock = 1_000_000;
const report = (body: string, headers: Record<string, string> = {}) =>
  new Request("https://admin.example/monitoring", {
    method: "POST",
    body,
    headers: { "sec-fetch-site": "same-origin", ...headers },
  });
const envelope = (type = "event") =>
  `{"event_id":"e1","sent_at":"now","dsn":"https://evil@evil.example/1"}\n{"type":"${type}"}\n{"exception":{"values":[]}}`;

afterEach(() => {
  vi.unstubAllGlobals();
  clock += 120_000;
});

describe("what is reported", () => {
  it("removes personal data and secrets from text", () => {
    const text = redact(
      `amina@example.test +255712345678 AKIAIOSFODNN7EXAMPLE ${"x".repeat(43)} eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.c2lnbmF0dXJl`,
    );
    expect(text).not.toMatch(/amina|255712|AKIA|x{40}|eyJ/);
  });

  it("is rebuilt from an allowlist", () => {
    const out = scrub({
      type: undefined,
      user: { email: "a@b.c" },
      breadcrumbs: [{ message: "typed a password" }],
      extra: { form: "secret" },
      contexts: { app: { token: "t" } },
      request: { url: "https://admin.example/invite?x=1#one-time-token", headers: { Cookie: "c" } },
      exception: {
        values: [
          {
            type: "TypeError",
            value: "bad a@b.co",
            stacktrace: {
              frames: [{ filename: "https://admin.example/a.js?dpl=1", lineno: 3, vars: { password: "p" } }],
            },
          },
        ],
      },
    });
    const text = JSON.stringify(out);
    expect(text).not.toMatch(/password|secret|token|Cookie|a@b|dpl/);
    expect(out.request).toEqual({ url: "https://admin.example/invite" });
    expect(out.exception?.values?.[0]?.stacktrace?.frames?.[0]).toMatchObject({ lineno: 3 });
  });

  it("leaves out answers the API gave on purpose", () => {
    expect(isExpected(new ApiError(403, "forbidden", ""))).toBe(true);
    expect(isExpected(new ApiError(0, "offline", ""))).toBe(true);
    expect(isExpected(new ApiError(500, "server_error", ""))).toBe(false);
    expect(isExpected(new TypeError("x"))).toBe(false);
  });
});

describe("the tunnel", () => {
  it("sends to the configured project, whatever the report says", async () => {
    const send = vi.fn().mockResolvedValue(new Response());
    vi.stubGlobal("fetch", send);
    expect(await forward(report(envelope()), DSN, clock)).toBe(204);
    const [url, init] = send.mock.calls[0] ?? [];
    expect(url).toBe("https://o1.ingest.sentry.io/api/42/envelope/?sentry_version=7&sentry_key=abc123");
    expect(init.body).not.toContain("evil");
    expect(init.redirect).toBe("error");
  });

  it("does nothing when reporting is off", async () => {
    const send = vi.fn();
    vi.stubGlobal("fetch", send);
    expect(await forward(report(envelope()), undefined, clock)).toBe(204);
    expect(send).not.toHaveBeenCalled();
  });

  it.each([
    ["another site", report(envelope(), { "sec-fetch-site": "cross-site" }), 403],
    ["no fetch metadata", report(envelope(), { "sec-fetch-site": "" }), 403],
    ["too large", report("x".repeat(70_000)), 413],
    ["not an envelope", report("hello"), 400],
    ["a replay", report(envelope("replay_recording")), 400],
    ["an attachment beside the event", report(`${envelope()}\n{"type":"attachment"}\nx`), 400],
  ])("refuses %s", async (_, request, status) => {
    const send = vi.fn();
    vi.stubGlobal("fetch", send);
    expect(await forward(request, DSN, clock)).toBe(status);
    expect(send).not.toHaveBeenCalled();
  });

  it("limits the rate", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response()));
    const codes = [];
    for (let i = 0; i < 62; i++) codes.push(await forward(report(envelope()), DSN, clock));
    expect(codes.filter((c) => c === 204)).toHaveLength(60);
    expect(codes.at(-1)).toBe(429);
  });

  it("survives a vendor outage", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("down")));
    expect(await forward(report(envelope()), DSN, clock)).toBe(204);
  });

  it("accepts only a well-formed DSN over TLS", () => {
    expect(parseDsn("http://k@sentry.example/1")).toBeNull();
    expect(parseDsn("https://sentry.example/1")).toBeNull();
    expect(parseDsn("https://k@sentry.example/../x")).toBeNull();
    expect(parseDsn("nonsense")).toBeNull();
  });
});
