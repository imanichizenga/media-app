import { createClient } from "@redis/client";
import { afterAll, beforeEach, describe, expect, test } from "vitest";
import CacheHandler from "../cache-handler.mjs";

const url = process.env.REDIS_URL ?? "redis://127.0.0.1:6379/7";
const redis = createClient({ url, socket: { reconnectStrategy: false, connectTimeout: 500 } });
redis.on("error", () => {});
const there = await redis.connect().then(
  () => true,
  () => false,
);
afterAll(() => redis.destroy());
const entry = { kind: "FETCH", data: { body: "x" }, revalidate: 60 };
const cache = new CacheHandler();

// CI has Redis (required there); a laptop may not.
describe.skipIf(!there && !process.env.CI)("the shared data cache", () => {
  beforeEach(() => redis.flushDb());
  test("gives back what it was given, to every instance", async () => {
    await cache.set("k", entry, { tags: ["latest"] });
    expect((await new CacheHandler().get("k", { tags: [] }))?.value).toEqual(entry);
  });
  test("forgets by tag, whoever says it", async () => {
    await cache.set("k", entry, { tags: ["latest"] });
    await cache.set("other", entry, { tags: ["site"] });
    await new CacheHandler().revalidateTag("latest");
    expect(await cache.get("k")).toBeNull();
    expect(await cache.get("other")).not.toBeNull();
  });
  test("an answer already on its way when the news changed is not kept", async () => {
    await cache.revalidateTag(["latest"]);
    await cache.set("k", entry, { tags: ["latest"] });
    expect(await cache.get("k")).toBeNull();
  });
  test("keeps data, never pages", async () => {
    await cache.set("p", { kind: "APP_PAGE", html: "<p>" }, {});
    expect(await cache.get("p")).toBeNull();
  });
});
