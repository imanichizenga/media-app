import { createHmac, timingSafeEqual } from "node:crypto";

export const WINDOW_SECONDS = 300;
/** The same bytes as the API's seo.delivery.sign. */
export const sign = (secret: string, timestamp: string, body: string) =>
  createHmac("sha256", secret).update(`${timestamp}.${body}`).digest("hex");

export function verify(
  secret: string,
  { timestamp, signature, body }: { timestamp: string | null; signature: string | null; body: string },
  now = Date.now(),
): boolean {
  if (!timestamp || !signature || !/^\d{10}$/.test(timestamp) || !/^[a-f0-9]{64}$/.test(signature))
    return false;
  if (Math.abs(now / 1000 - Number(timestamp)) > WINDOW_SECONDS) return false;
  return timingSafeEqual(Buffer.from(sign(secret, timestamp, body), "hex"), Buffer.from(signature, "hex"));
}

export type Message = { id: string; tags: string[]; paths: string[] };
const listOf = (value: unknown, each: RegExp, most: number): value is string[] =>
  Array.isArray(value) && value.length <= most && value.every((v) => typeof v === "string" && each.test(v));
export function messageOf(body: string): Message | null {
  try {
    const m = JSON.parse(body);
    if (typeof m?.id !== "string" || !/^[a-z0-9-]{1,64}$/i.test(m.id)) return null;
    if (!listOf(m.tags, /^[\w:.-]{1,200}$/, 500) || !listOf(m.paths, /^\/[^\s\\]{0,240}$/, 500)) return null;
    return { id: m.id, tags: m.tags, paths: m.paths };
  } catch {
    return null;
  }
}
