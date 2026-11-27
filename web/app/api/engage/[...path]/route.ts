import { anonymous, asReader, json, refuse, sameSite, signedIn } from "@/lib/reader";

/**
 * The reader's engagement, through this server (ADR-0050). Only these shapes pass; anything else is 404. Reading is
 * open to guests (counts, comments); everything else needs a reader and comes from this site's own pages.
 */
const ALLOWED = [
  /^state$/,
  /^posts\/[0-9a-f-]{36}\/(like|bookmark|comments|opened|readers)$/,
  /^comments\/[0-9a-f-]{36}(\/like)?$/,
  /^follows\/(author|category)\/[0-9a-f-]{36}$/,
];

async function pass(request: Request, params: Promise<{ path: string[] }>) {
  const path = (await params).path.join("/");
  if (!ALLOWED.some((r) => r.test(path))) return json({ code: "not_found" }, 404);
  const query = new URL(request.url).search;
  const target = `engagement/${path}${query}`;
  if (request.method === "GET") {
    const { status, body } = (await signedIn()) ? await asReader(target) : await anonymous(target);
    return json(body, status);
  }
  if (!(await sameSite(request))) return refuse();
  const text = request.method === "POST" ? (await request.text()).slice(0, 8000) : undefined;
  // An opening is counted for guests too (by the random id their browser keeps).
  const guest = path.endsWith("/opened") && !(await signedIn());
  const ask = guest ? anonymous : asReader;
  const { status, body } = await ask(target, { method: request.method, body: text });
  return json(body, status);
}
type Ctx = { params: Promise<{ path: string[] }> };
export const GET = (r: Request, c: Ctx) => pass(r, c.params);
export const POST = (r: Request, c: Ctx) => pass(r, c.params);
export const PUT = (r: Request, c: Ctx) => pass(r, c.params);
export const DELETE = (r: Request, c: Ctx) => pass(r, c.params);
