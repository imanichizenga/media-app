import "server-only";
import { createHmac, timingSafeEqual } from "node:crypto";
import { cookies, headers } from "next/headers";
import { env } from "./env";

/**
 * The reader's session, held by this site's server (ADR-0050, SPEC 9.1): the tokens live in httpOnly cookies that no
 * script can read; the island asks this server, which asks the API with the access token and quietly renews it.
 * A cookie readable by script, `signed=1`, only says that someone is signed in, so pages that everyone shares stay
 * the same document for everyone and the island knows whether to ask who.
 */
const ACCESS = "rd_at";
const REFRESH = "rd_rt";
export const SIGNED = "signed";
const MONTHS_2 = 60 * 24 * 3600;

const secure = () => env.site.startsWith("https://") || process.env.NODE_ENV === "production";
type Jar = Awaited<ReturnType<typeof cookies>>;

export type Pair = { access: string; refresh: string; expires_in: number };

export function keep(jar: Jar, pair: Pair) {
  const base = { httpOnly: true, secure: secure(), sameSite: "lax" as const, path: "/" };
  jar.set(ACCESS, pair.access, { ...base, maxAge: Math.max(60, pair.expires_in - 30) });
  jar.set(REFRESH, pair.refresh, { ...base, maxAge: MONTHS_2 });
  jar.set(SIGNED, "1", { secure: secure(), sameSite: "lax", path: "/", maxAge: MONTHS_2 });
}
export function forget(jar: Jar) {
  for (const name of [ACCESS, REFRESH, SIGNED]) jar.delete(name);
}

/** The reader's own address, signed for the API, so its SMS limits count readers and not this server. */
async function forwarded(): Promise<Record<string, string>> {
  const h = await headers();
  // As the API does it: only the hops this platform runs (CDN, load balancer) may append, so the address is the
  // one `TRUSTED_PROXY_HOPS` from the right. Nothing in front of the site (local): nothing is told.
  const hops = Number(process.env.TRUSTED_PROXY_HOPS ?? 0);
  const chain = (h.get("x-forwarded-for") ?? "")
    .split(",")
    .map((p) => p.trim())
    .filter(Boolean);
  const ip = hops > 0 && chain.length >= hops ? (chain.at(-hops) ?? "") : "";
  if (!ip) return {};
  const mac = createHmac("sha256", env.revalidateSecret).update(`reader-ip:${ip}`).digest("hex");
  return { "x-reader-ip": ip, "x-reader-ip-mac": mac };
}

export type Answer = { status: number; body: unknown };

async function send(path: string, init: RequestInit, access?: string): Promise<Response> {
  const extra = await forwarded();
  return fetch(`${env.api}/api/v1/${path}`, {
    ...init,
    cache: "no-store",
    headers: {
      "content-type": "application/json",
      "user-agent": (await headers()).get("user-agent") ?? "",
      ...extra,
      ...(access ? { authorization: `Bearer ${access}` } : {}),
      ...(init.headers as Record<string, string> | undefined),
    },
    signal: AbortSignal.timeout(10_000),
  });
}
const read = async (res: Response): Promise<Answer> => ({
  status: res.status,
  body: res.status === 204 ? null : await res.json().catch(() => null),
});

/** Without a reader. */
export async function anonymous(path: string, init: RequestInit = {}): Promise<Answer> {
  return read(await send(path, init));
}

/** As the signed-in reader: renews the access token once if it has gone, and signs out when that fails. */
export async function asReader(path: string, init: RequestInit = {}): Promise<Answer> {
  const jar = await cookies();
  let access = jar.get(ACCESS)?.value;
  const refresh = jar.get(REFRESH)?.value;
  if (!access && !refresh) return { status: 401, body: { code: "unauthenticated" } };
  let res = access ? await send(path, init, access) : null;
  if ((!res || res.status === 401) && refresh) {
    const renewed = await send("auth/refresh", { method: "POST", body: JSON.stringify({ refresh }) });
    if (renewed.status !== 200) {
      forget(jar);
      return read(renewed);
    }
    const pair = (await renewed.json()) as Pair;
    keep(jar, pair);
    access = pair.access;
    res = await send(path, init, access);
  }
  return read(res as Response);
}

export const signedIn = async () => (await cookies()).has(REFRESH);
export const refreshToken = async () => (await cookies()).get(REFRESH)?.value ?? "";

/** Unsafe requests come from this site's own pages: the Origin says so (and the cookies are SameSite=Lax). */
export async function sameSite(request: Request): Promise<boolean> {
  const origin = request.headers.get("origin");
  if (!origin) return false;
  const a = Buffer.from(origin);
  const b = Buffer.from(new URL(env.site).origin);
  const local = process.env.WEB_LOCAL && /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
  return Boolean(local) || (a.length === b.length && timingSafeEqual(a, b));
}

/** A JSON answer that no one keeps. */
export const json = (body: unknown, status = 200) =>
  new Response(status === 204 ? null : JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", "cache-control": "no-store" },
  });
export const refuse = () => json({ code: "csrf_failed" }, 403);
