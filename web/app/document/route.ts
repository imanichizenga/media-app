import { PUBLIC } from "@/lib/cdn";
import { policy, REPORTING_ENDPOINTS } from "@/lib/csp";
import { env } from "@/lib/env";
import { failure } from "@/lib/failure";
import { internalToken } from "@/lib/internal";
import { slim } from "@/lib/slim";

export const dynamic = "force-dynamic";
const host = process.env.HOSTNAME && process.env.HOSTNAME !== "0.0.0.0" ? process.env.HOSTNAME : "127.0.0.1";
const SELF = `http://${host}:${process.env.PORT || 3000}`;

/** The page as a document: rendered by the App Router, sent without its client runtime (ADR-0046). */
export async function GET(request: Request) {
  const path = request.headers.get("x-path") ?? "/";
  const csp = policy({ media: process.env.MEDIA_ORIGIN, local: Boolean(process.env.WEB_LOCAL) });
  const security = { "content-security-policy": csp, "reporting-endpoints": REPORTING_ENDPOINTS };
  const fail = async () =>
    new Response(await failure(path), {
      status: 503,
      headers: {
        "content-type": "text/html; charset=utf-8",
        ...security,
        // The CDN goes on showing what it has (stale-if-error).
        "cache-control": "no-store",
        "retry-after": "30",
      },
    });
  const render = (what: string) =>
    fetch(SELF + what, {
      cache: "no-store",
      redirect: "manual",
      headers: {
        "x-internal": internalToken(env.revalidateSecret),
        "user-agent": "document",
        "accept-encoding": "identity",
      },
      signal: AbortSignal.timeout(15_000),
    });
  let res: Response;
  try {
    res = await render(path);
    // The framework's own 404 is drawn in the browser; ours is drawn here.
    if (res.status === 404) res = await render(/^\/en(\/|$)/.test(path) ? "/en/missing" : "/missing");
  } catch {
    return fail();
  }
  const location = res.headers.get("location");
  if (res.status >= 300 && res.status < 400 && location) {
    const to = new URL(location, env.site);
    // For ever is 301, the word every crawler knows.
    return new Response(null, {
      status: res.status === 308 ? 301 : res.status,
      headers: { location: to.pathname + to.search, "cache-control": PUBLIC },
    });
  }
  if (res.status >= 500) return fail();
  const { html, status } = slim(await res.text());
  return new Response(html, {
    status: status ?? res.status,
    headers: { "content-type": "text/html; charset=utf-8", ...security, "cache-control": PUBLIC },
  });
}
