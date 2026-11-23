const MAX_BYTES = 64 * 1024;
const PER_MINUTE = 60;

type Dsn = { url: string; dsn: string };
export function parseDsn(raw: string | undefined): Dsn | null {
  if (!raw) return null;
  try {
    const u = new URL(raw);
    const local = ["127.0.0.1", "localhost"].includes(u.hostname);
    const project = u.pathname.replace(/^\/+/, "");
    if ((u.protocol !== "https:" && !local) || !u.username || !/^\d+$/.test(project)) return null;
    const query = `sentry_version=7&sentry_key=${encodeURIComponent(u.username)}`;
    return { dsn: raw, url: `${u.protocol}//${u.host}/api/${project}/envelope/?${query}` };
  } catch {
    return null;
  }
}

let windowStart = 0;
let used = 0;
export function allow(now: number): boolean {
  if (now - windowStart >= 60_000) [windowStart, used] = [now, 0];
  used += 1;
  return used <= PER_MINUTE;
}

/**
 * Forwards an error report to the one configured project. Fixed destination, same-origin callers, bounded size and
 * rate: it cannot be used to reach anything else, or to flood the error quota.
 */
export async function forward(request: Request, raw: string | undefined, now = Date.now()): Promise<number> {
  const target = parseDsn(raw);
  if (!target) return 204;
  if (request.headers.get("sec-fetch-site") !== "same-origin") return 403;
  if (Number(request.headers.get("content-length") ?? 0) > MAX_BYTES) return 413;
  if (!allow(now)) return 429;
  const body = await request.text();
  if (body.length > MAX_BYTES) return 413;
  const split = body.indexOf("\n");
  let header: Record<string, unknown>;
  try {
    header = JSON.parse(body.slice(0, split));
  } catch {
    return 400;
  }
  const items = body.slice(split + 1);
  // Error events only: no replays, attachments, sessions or profiles can be smuggled through.
  const types = items.split("\n").filter((line) => /^\{[^{}]*"type":"[a-z_]+"[^{}]*\}$/.test(line));
  if (types.length !== 1 || !types[0]?.includes('"type":"event"')) return 400;
  const envelope = `${JSON.stringify({ event_id: header.event_id, sent_at: header.sent_at, dsn: target.dsn })}\n${items}`;
  try {
    await fetch(target.url, {
      method: "POST",
      body: envelope,
      headers: { "content-type": "application/x-sentry-envelope" },
      redirect: "error",
      signal: AbortSignal.timeout(3_000),
    });
  } catch {
    // Reporting must never become a second failure for the person.
  }
  return 204;
}
