import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";

// Just enough of a page for islands/progress.ts: one element, its classes and its transform.
type Bar = {
  id: string;
  classes: Set<string>;
  style: { transform: string };
  attrs: Record<string, string>;
  classList: { toggle: (c: string, force: boolean) => unknown; contains: (c: string) => boolean };
  setAttribute: (name: string, value: string) => void;
};
let bar: Bar | null;
let pageshow: ((e: { persisted: boolean }) => void) | null;
const on = () => bar?.classList.contains("on") ?? false;
const scale = () => Number(/scaleX\(([\d.]+)\)/.exec(bar?.style.transform ?? "")?.[1] ?? 0);

beforeEach(() => {
  vi.useFakeTimers();
  vi.resetModules();
  bar = null;
  pageshow = null;
  const make = () => {
    const classes = new Set<string>();
    bar = {
      id: "",
      classes,
      style: { transform: "" },
      attrs: {},
      classList: {
        toggle: (c: string, force: boolean) => (force ? classes.add(c) : classes.delete(c)),
        contains: (c: string) => classes.has(c),
      },
      setAttribute(name: string, value: string) {
        this.attrs[name] = value;
      },
    };
    return bar;
  };
  vi.stubGlobal("document", { createElement: make, body: { append: () => {} } });
  vi.stubGlobal("addEventListener", (type: string, f: (e: { persisted: boolean }) => void) => {
    if (type === "pageshow") pageshow = f;
  });
  vi.stubGlobal("window", globalThis);
});
afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

describe("the loading bar", () => {
  test("a quick page never shows it", async () => {
    const { start, finish } = await import("../islands/progress");
    start();
    vi.advanceTimersByTime(100);
    finish();
    vi.advanceTimersByTime(2000);
    expect(bar === null || !on()).toBe(true);
  });

  test("a slow page shows it, creeping below 90%, then it fills and fades", async () => {
    const { start, finish } = await import("../islands/progress");
    start();
    vi.advanceTimersByTime(130);
    expect(on()).toBe(true);
    expect(bar?.attrs["aria-hidden"]).toBe("true");
    const early = scale();
    vi.advanceTimersByTime(10_000);
    expect(scale()).toBeGreaterThan(early);
    expect(scale()).toBeLessThan(0.9);
    finish();
    expect(scale()).toBe(1);
    vi.advanceTimersByTime(250);
    expect(on()).toBe(false);
    vi.advanceTimersByTime(400);
    expect(scale()).toBe(0);
  });

  test("another link pressed while it runs carries on with the same bar", async () => {
    const { start } = await import("../islands/progress");
    start();
    vi.advanceTimersByTime(2000);
    const before = scale();
    start();
    vi.advanceTimersByTime(200);
    expect(on()).toBe(true);
    expect(scale()).toBeGreaterThanOrEqual(before);
  });

  test("a page restored from the back-forward cache has no bar left over", async () => {
    const { start } = await import("../islands/progress");
    start();
    vi.advanceTimersByTime(500);
    expect(on()).toBe(true);
    pageshow?.({ persisted: true });
    vi.advanceTimersByTime(5000);
    expect(on()).toBe(false);
    expect(scale()).toBe(0);
  });

  test("finishing with nothing started does nothing", async () => {
    const { finish } = await import("../islands/progress");
    finish();
    vi.advanceTimersByTime(1000);
    expect(bar).toBeNull();
  });
});
