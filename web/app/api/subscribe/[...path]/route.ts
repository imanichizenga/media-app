import { env } from "@/lib/env";
import { internalToken } from "@/lib/internal";
import { isLocale } from "@/lib/locale";
import { accessToken, asReader, json, refuse, sameSite } from "@/lib/reader";

const host = process.env.HOSTNAME && process.env.HOSTNAME !== "0.0.0.0" ? process.env.HOSTNAME : "127.0.0.1";
const SELF = `http://${host}:${process.env.PORT || 3000}`;

/**
 * Subscriptions through this server (ADR-0052), for the signed-in reader: paying, watching a payment, their plan, and
 * the whole of a story for subscribers, drawn by this site's own page (app/[locale]/subscriber), for the island to put in place.
 */
const UUID = "[0-9a-f-]{36}";
const READS = [new RegExp(`^payments/${UUID}$`), /^mine$/, new RegExp(`^posts/${UUID}$`)];

async function pass(request: Request, params: Promise<{ path: string[] }>) {
  const path = (await params).path.join("/");
  const url = new URL(request.url);
  const locale = url.searchParams.get("locale") ?? "sw";
  if (!isLocale(locale)) return json({ code: "not_found" }, 404);
  if (request.method === "POST") {
    if (path !== "checkout") return json({ code: "not_found" }, 404);
    if (!(await sameSite(request))) return refuse();
    const text = (await request.text()).slice(0, 2000);
    const { status, body } = await asReader("subscriptions/checkout", { method: "POST", body: text });
    return json(body, status);
  }
  if (!READS.some((r) => r.test(path))) return json({ code: "not_found" }, 404);
  const { status, body } = await asReader(`subscriptions/${path}?locale=${locale}`);
  if (!path.startsWith("posts/") || status !== 200) return json(body, status);
  // Paid time is checked (and the reader's token renewed) above; the story is drawn by this site's own page.
  const page = await fetch(`${SELF}/${locale}/subscriber/${path.slice(6)}`, {
    cache: "no-store",
    headers: {
      "x-internal": internalToken(env.revalidateSecret),
      "x-reader-access": await accessToken(),
      "accept-encoding": "identity",
    },
    signal: AbortSignal.timeout(15_000),
  }).catch(() => null);
  const text = page?.ok ? await page.text() : "";
  const open = '<div id="full-body">';
  const start = text.indexOf(open);
  const end = text.indexOf('</div><i id="full-end"');
  if (start < 0 || end < start) return json({ code: "unavailable" }, 503);
  return json({ html: text.slice(start + open.length, end) });
}
type Ctx = { params: Promise<{ path: string[] }> };
export const GET = (r: Request, c: Ctx) => pass(r, c.params);
export const POST = (r: Request, c: Ctx) => pass(r, c.params);
