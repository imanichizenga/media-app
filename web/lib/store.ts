import "server-only";
import { createClient } from "@redis/client";
import { env } from "./env";
import { WINDOW_SECONDS } from "./signature";

let client: ReturnType<typeof createClient> | null = null;
async function redis() {
  if (!client) {
    client = createClient({ url: env.redis, socket: { connectTimeout: 2000 }, disableOfflineQueue: true });
    client.on("error", () => {});
  }
  if (!client.isOpen) await client.connect();
  return client;
}
/** True the first time only. Fails when Redis does: an order that may be a repeat is not obeyed. */
export async function firstTime(id: string): Promise<boolean> {
  const done = await (await redis()).set(`web:nonce:${id}`, "1", {
    condition: "NX",
    expiration: { type: "EX", value: 2 * WINDOW_SECONDS + 60 },
  });
  return done === "OK";
}
/** Read by cache-handler.mjs. Written before the sender is answered: it purges the CDN next. */
export async function forget(tags: string[]): Promise<void> {
  if (tags.length === 0) return;
  const now = String(Date.now());
  await (await redis()).hSet("web:cache:tags", Object.fromEntries(tags.map((t) => [t, now])));
}
