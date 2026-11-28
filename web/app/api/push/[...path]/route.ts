import { anonymous, asReader, json, refuse, sameSite, signedIn } from "@/lib/reader";

/**
 * Notifications of new stories (ADR-0051), through this server: the site's public push key, and this browser
 * subscribing or leaving. Anyone may, signed in or not; only this site's own pages may change it.
 */
async function pass(request: Request, params: Promise<{ path: string[] }>) {
  const path = (await params).path.join("/");
  if (request.method === "GET" && path === "key") {
    const { status, body } = await anonymous("push/key");
    return json(body, status);
  }
  if (path !== "subscriptions" || !["POST", "DELETE"].includes(request.method)) {
    return json({ code: "not_found" }, 404);
  }
  if (!(await sameSite(request))) return refuse();
  const text = (await request.text()).slice(0, 4000);
  const ask = (await signedIn()) ? asReader : anonymous;
  const { status, body } = await ask("push/subscriptions", { method: request.method, body: text });
  return json(body, status);
}
type Ctx = { params: Promise<{ path: string[] }> };
export const GET = (r: Request, c: Ctx) => pass(r, c.params);
export const POST = (r: Request, c: Ctx) => pass(r, c.params);
export const DELETE = (r: Request, c: Ctx) => pass(r, c.params);
