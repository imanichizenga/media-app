import "server-only";
import { createHash, randomBytes } from "node:crypto";
import { cookies } from "next/headers";
import { env } from "./env";
import { anonymous, keep, type Pair } from "./reader";

/**
 * Google and Apple on the website: the authorization code flow (ADR-0050). This server makes the state (against
 * forged callbacks), a PKCE verifier for Google and a nonce, keeps them in a short httpOnly cookie, and hands the code
 * to the API, which exchanges it with the client secret and verifies the identity token. No third-party script runs
 * on our pages.
 */
type Flow = { state: string; verifier: string; nonce: string; next: string };
const COOKIE = "rd_oauth";

export const redirectUri = (provider: "google" | "apple") => `${env.site}/api/auth/${provider}/callback`;
/** Only this site's own paths; anything else goes home. */
export const safeNext = (next: string | null) =>
  next && /^\/(?![/\\])/.test(next) ? next.slice(0, 300) : "/";

const random = () => randomBytes(32).toString("base64url");

export async function begin(next: string, crossSite: boolean): Promise<Flow & { challenge: string }> {
  const flow: Flow = { state: random(), verifier: random(), nonce: random(), next: safeNext(next) };
  (await cookies()).set(COOKIE, JSON.stringify(flow), {
    httpOnly: true,
    secure: env.site.startsWith("https://"),
    // Apple answers with a POST from its own site: only a SameSite=None cookie comes along with it.
    sameSite: crossSite ? "none" : "lax",
    path: "/api/auth",
    maxAge: 600,
  });
  return { ...flow, challenge: createHash("sha256").update(flow.verifier).digest("base64url") };
}

/** The flow this callback belongs to, once; null when the state does not match (forged or stale). */
export async function finish(state: string | null): Promise<Flow | null> {
  const jar = await cookies();
  const raw = jar.get(COOKIE)?.value;
  jar.delete(COOKIE);
  if (!raw || !state) return null;
  try {
    const flow = JSON.parse(raw) as Flow;
    return flow.state === state ? flow : null;
  } catch {
    return null;
  }
}

export async function methods(): Promise<{ google_client_id: string; apple_services_id: string }> {
  const { body } = await anonymous("auth/methods");
  return body as { google_client_id: string; apple_services_id: string };
}

/** Back to where the reader was; `#signed-in` lets the page finish what was asked before (intent resume). */
export async function land(provider: "google" | "apple", body: Record<string, unknown>, next: string) {
  const { status, body: answer } = await anonymous(`auth/${provider}`, {
    method: "POST",
    body: JSON.stringify({ ...body, redirect_uri: redirectUri(provider), device: "web" }),
  });
  if (status !== 200) return Response.redirect(new URL(`${next}#sign-in-failed`, env.site), 303);
  keep(await cookies(), answer as Pair);
  return Response.redirect(new URL(`${next}#signed-in`, env.site), 303);
}
