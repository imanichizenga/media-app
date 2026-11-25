// The data cache, shared by every instance: one revalidation reaches all of them (ADR-0046). Pages themselves are
// never kept here (each has its own nonce); the CDN keeps those. Without Redis the site still works, uncached.
import { createClient } from "@redis/client";

const PREFIX = "web:cache:";
const TAGS = `${PREFIX}tags`;
const DAY = 86_400;
const url = process.env.REDIS_URL || "redis://127.0.0.1:6379/7";
globalThis.__newsCache ??= { client: null, quietUntil: 0 };
const state = globalThis.__newsCache;

async function redis() {
  if (process.env.NEXT_PHASE === "phase-production-build" || Date.now() < state.quietUntil) return null;
  if (state.client?.isReady) return state.client;
  try {
    if (!state.client) {
      state.client = createClient({
        url,
        socket: { connectTimeout: 1000, reconnectStrategy: (n) => Math.min(n * 200, 5000) },
        disableOfflineQueue: true,
        commandsQueueMaxLength: 5000,
      });
      state.client.on("error", () => {});
      await state.client.connect();
    }
    return state.client.isReady ? state.client : null;
  } catch {
    state.quietUntil = Date.now() + 2000;
    state.client?.destroy?.();
    state.client = null;
    return null;
  }
}
/** A cache that does not answer is a cache that has nothing. */
async function quietly(work) {
  try {
    const client = await redis();
    return client ? await work(client) : null;
  } catch {
    return null;
  }
}

export default class CacheHandler {
  async get(key, ctx = {}) {
    return quietly(async (client) => {
      const raw = await client.get(PREFIX + key);
      if (!raw) return null;
      const entry = JSON.parse(raw);
      const tags = [...new Set([...(entry.tags ?? []), ...(ctx.tags ?? []), ...(ctx.softTags ?? [])])];
      if (tags.length > 0) {
        const times = await client.hmGet(TAGS, tags);
        // Two seconds more: an answer that was already on its way when the news changed may be the old one.
        if (times.some((t) => t && Number(t) + 2000 >= entry.lastModified)) return null;
      }
      return { lastModified: entry.lastModified, value: entry.value };
    });
  }
  async set(key, value, ctx = {}) {
    if (value === null) return void (await quietly((client) => client.del(PREFIX + key)));
    if (value.kind !== "FETCH") return;
    const tags = [...new Set([...(ctx.tags ?? []), ...(value.tags ?? [])])];
    // Kept well past its time: an old answer is shown while a new one is made, or while the API is away.
    const entry = JSON.stringify({ value, tags, lastModified: Date.now() });
    await quietly((client) =>
      client.set(PREFIX + key, entry, { expiration: { type: "EX", value: 2 * DAY } }),
    );
  }
  async revalidateTag(tags) {
    const list = [tags].flat().filter(Boolean);
    if (list.length === 0) return;
    const now = String(Date.now());
    const client = await redis();
    // Said aloud: the sender must try again, or readers would keep the old page.
    if (!client) throw new Error("the cache cannot be reached");
    await client.hSet(TAGS, Object.fromEntries(list.map((t) => [t, now])));
  }
  resetRequestCache() {}
}
