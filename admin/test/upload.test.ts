import { describe, expect, it, vi } from "vitest";
import { type Api, partSizeFor, upload } from "../lib/upload";

const MB = 1024 ** 2;
const file = (size: number) => new File([new Uint8Array(size)], "v.mp4", { type: "video/mp4" });
function fake(over: Partial<Api> = {}) {
  const sent: number[] = [];
  const api: Api = {
    begin: async () => ({ id: "a", partSize: 4, partCount: 5 }),
    existing: async () => [],
    sign: async (_, numbers) => Object.fromEntries(numbers.map((n) => [n, `u/${n}`])),
    put: async (url, body, progress) => {
      progress(body.size);
      sent.push(Number(url.split("/")[1]));
    },
    complete: vi.fn(async () => {}),
    sleep: async () => {},
    ...over,
  };
  return { api, sent };
}
const live = () => new AbortController().signal;

describe("upload", () => {
  it("sends every part once and completes", async () => {
    const { api, sent } = fake();
    const seen: number[] = [];
    expect(await upload(file(18), "video", api, (n) => seen.push(n), live())).toBe("a");
    expect([...sent].sort()).toEqual([1, 2, 3, 4, 5]);
    expect(seen.at(-1)).toBe(18);
    expect(Math.max(...seen)).toBe(18);
    expect(api.complete).toHaveBeenCalledTimes(1);
  });
  it("sends only what is missing when it resumes", async () => {
    const { api, sent } = fake({ existing: async () => [1, 2, 4] });
    const seen: number[] = [];
    await upload(file(18), "video", api, (n) => seen.push(n), live(), { id: "a", partSize: 4, partCount: 5 });
    expect([...sent].sort()).toEqual([3, 5]);
    expect(seen[0]).toBe(12);
    expect(seen.at(-1)).toBe(18);
  });
  it("waits longer each time and signs again after a cut", async () => {
    const waits: number[] = [];
    let cuts = 3;
    const signed: number[][] = [];
    const base = fake();
    const { api, sent } = fake({
      sleep: async (ms) => void waits.push(ms),
      sign: async (id, n) => {
        signed.push(n);
        return base.api.sign(id, n);
      },
    });
    const put = api.put;
    api.put = async (url, ...rest) => {
      if (url === "u/2" && cuts-- > 0) throw new Error("network");
      return put(url, ...rest);
    };
    await upload(file(18), "video", api, () => {}, live());
    expect(waits).toEqual([1000, 2000, 4000]);
    expect([...sent].sort()).toEqual([1, 2, 3, 4, 5]);
    expect(signed.flat().filter((n) => n === 2)).toHaveLength(4);
  });
  it("gives up in the end, without completing", async () => {
    const { api } = fake({
      put: async () => {
        throw new Error("network");
      },
    });
    await expect(upload(file(18), "video", api, () => {}, live())).rejects.toThrow("network");
    expect(api.complete).not.toHaveBeenCalled();
  });
  it("stops at once when it is paused", async () => {
    const stop = new AbortController();
    const { api, sent } = fake();
    const put = api.put;
    api.put = async (...args) => {
      stop.abort();
      return put(...args);
    };
    await expect(upload(file(18), "video", api, () => {}, stop.signal)).rejects.toThrow();
    expect(sent.length).toBeLessThanOrEqual(3);
    expect(api.complete).not.toHaveBeenCalled();
  });
  it("uses the server's part size", () => {
    expect(partSizeFor(10)).toBe(8 * MB);
    expect(partSizeFor(1024 ** 3)).toBe(8 * MB);
    expect(partSizeFor(8 * 1024 ** 3) % 1).toBe(0);
    expect(partSizeFor(100 * 1024 ** 3)).toBe(Math.ceil((100 * 1024 ** 3) / 9000));
  });
});
