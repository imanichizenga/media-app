import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { ApiError } from "../lib/api";
import { type Data, Draft, type Post } from "../lib/editor/draft";

const post = (version: number, data: Partial<Data> = {}) =>
  ({ id: "p", version, data: { is_evergreen: false, texts: { sw: { headline: "A" } }, ...data } }) as Post;
type Call = { version: number; data: Partial<Data>; autosave: boolean };
function setup(answer?: (call: Call, n: number) => Promise<Post> | Post) {
  const calls: Call[] = [];
  const draft = new Draft(post(1), {
    delay: 100,
    save: async (version, data, autosave) => {
      const call = { version, data, autosave };
      calls.push(call);
      if (answer) return answer(call, calls.length);
      return post(version + 1, data as Partial<Data>);
    },
  });
  return { draft, calls };
}
beforeEach(() => void vi.useFakeTimers());
afterEach(() => void vi.useRealTimers());

describe("Draft", () => {
  it("sends only what changed, once the typing pauses", async () => {
    const { draft, calls } = setup();
    draft.changeText("sw", { headline: "AB" });
    await vi.advanceTimersByTimeAsync(60);
    draft.changeText("sw", { headline: "ABC" });
    await vi.advanceTimersByTimeAsync(60);
    expect(calls).toEqual([]);
    await vi.advanceTimersByTimeAsync(60);
    expect(calls).toEqual([{ version: 1, data: { texts: { sw: { headline: "ABC" } } }, autosave: true }]);
    expect(draft.get().state).toBe("saved");
  });

  it("keeps what is typed while a save is on its way", async () => {
    let release = (_: Post) => {};
    const { draft, calls } = setup((_, n) =>
      n === 1 ? new Promise<Post>((r) => (release = r)) : post(3, { texts: { sw: { headline: "two" } } }),
    );
    draft.changeText("sw", { headline: "one" });
    await vi.advanceTimersByTimeAsync(100);
    draft.changeText("sw", { headline: "two" });
    release(post(2, { texts: { sw: { headline: "one", slug: "one" } } }));
    await vi.advanceTimersByTimeAsync(0);
    expect(draft.get().data.texts?.sw).toMatchObject({ headline: "two", slug: "one" });
    await vi.advanceTimersByTimeAsync(100);
    expect(calls[1]).toMatchObject({ version: 2, data: { texts: { sw: { headline: "two" } } } });
  });

  it("never sends two saves at once, and flush waits for both", async () => {
    let open = 0;
    let most = 0;
    const { draft, calls } = setup(async ({ version, data }) => {
      most = Math.max(most, ++open);
      await new Promise((r) => setTimeout(r, 50));
      open--;
      return post(version + 1, data as Partial<Data>);
    });
    draft.change({ is_evergreen: true });
    const first = draft.flush(false);
    draft.change({ is_sensitive: true });
    const second = draft.flush(false);
    await vi.advanceTimersByTimeAsync(300);
    expect(await Promise.all([first, second])).toEqual([true, true]);
    expect(most).toBe(1);
    expect(calls.map((c) => c.version)).toEqual([1, 2]);
  });

  it("keeps trying when the network fails, waiting longer each time", async () => {
    const { draft, calls } = setup(({ version, data }, n) => {
      if (n < 3) throw new ApiError(0, "offline", "");
      return post(version + 1, data as Partial<Data>);
    });
    draft.changeText("sw", { headline: "B" });
    await vi.advanceTimersByTimeAsync(100);
    expect(draft.get().state).toBe("offline");
    await vi.advanceTimersByTimeAsync(2_000);
    expect(calls).toHaveLength(2);
    await vi.advanceTimersByTimeAsync(3_900);
    expect(calls).toHaveLength(2);
    await vi.advanceTimersByTimeAsync(200);
    expect(draft.get().state).toBe("saved");
    expect(calls[2]?.data).toEqual({ texts: { sw: { headline: "B" } } });
  });

  it.each([
    ["stale_version", 409, "conflict"],
    ["locked", 409, "locked"],
  ])("stops and asks on %s, losing nothing", async (code, status, state) => {
    const { draft, calls } = setup(() => {
      throw new ApiError(status, code, "");
    });
    draft.changeText("sw", { headline: "Mine" });
    await vi.advanceTimersByTimeAsync(60_000);
    draft.changeText("sw", { headline: "Mine still" });
    await vi.advanceTimersByTimeAsync(60_000);
    expect(calls).toHaveLength(1);
    expect(draft.get()).toMatchObject({ state, data: { texts: { sw: { headline: "Mine still" } } } });
    expect(await draft.flush(false)).toBe(false);
    expect(draft.dirty).toBe(true);
  });

  it("does not repeat what the server refused, until something changes", async () => {
    const { draft, calls } = setup((c, n) => {
      if (n === 1) throw new ApiError(400, "validation_error", "");
      return post(2, c.data as Partial<Data>);
    });
    draft.change({ source_url: "bad" });
    await vi.advanceTimersByTimeAsync(60_000);
    expect(calls).toHaveLength(1);
    expect(draft.get().state).toBe("invalid");
    draft.change({ source_url: "https://example.org" });
    await vi.advanceTimersByTimeAsync(100);
    expect(draft.get().state).toBe("saved");
  });

  it("saves again after taking over the lock", async () => {
    const { draft, calls } = setup((c, n) => {
      if (n === 1) throw new ApiError(409, "locked", "");
      return post(2, c.data as Partial<Data>);
    });
    draft.change({ is_evergreen: true });
    await vi.advanceTimersByTimeAsync(100);
    draft.unlock();
    await vi.advanceTimersByTimeAsync(0);
    expect(calls).toHaveLength(2);
    expect(draft.get().state).toBe("saved");
  });

  it("says nothing is unsaved after taking over with nothing typed", () => {
    const { draft } = setup();
    draft.unlock();
    expect(draft.get().state).toBe("clean");
  });

  it("takes news about files without touching the words, and only about this version", () => {
    const { draft } = setup();
    draft.changeText("sw", { headline: "mine" });
    draft.refresh({ ...post(1, { texts: { sw: { headline: "theirs" } } }), problems: ["body"] } as Post);
    expect(draft.get().post.problems).toEqual(["body"]);
    expect(draft.get().data.texts?.sw?.headline).toBe("mine");
    draft.refresh({ ...post(9), problems: [] } as unknown as Post);
    expect(draft.get().post.problems).toEqual(["body"]);
  });
});
