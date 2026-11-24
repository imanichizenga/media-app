import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { Realtime } from "../lib/realtime";

class FakeSocket {
  static all: FakeSocket[] = [];
  sent: { type: string; topic?: string; ticket?: string }[] = [];
  onopen: () => void = () => {};
  onmessage: (e: { data: string }) => void = () => {};
  onclose: (e: { code: number }) => void = () => {};
  closed = false;
  constructor() {
    FakeSocket.all.push(this);
  }
  send(raw: string) {
    this.sent.push(JSON.parse(raw));
  }
  close() {
    this.closed = true;
    this.onclose({ code: 1000 });
  }
  say(message: object) {
    this.onmessage({ data: JSON.stringify(message) });
  }
  drop(code = 1006) {
    this.onclose({ code });
  }
}
const last = () => FakeSocket.all.at(-1) as FakeSocket;
const make = (ticket = async () => "t") =>
  new Realtime({ open: () => new FakeSocket() as unknown as WebSocket, ticket, random: () => 1 });
async function ready() {
  last().onopen();
  await vi.advanceTimersByTimeAsync(0);
  last().say({ type: "ready" });
}

beforeEach(() => {
  FakeSocket.all = [];
  vi.useFakeTimers();
});
afterEach(() => vi.useRealTimers());

describe("Realtime", () => {
  it("opens nothing until something is watched", () => {
    make();
    expect(FakeSocket.all).toHaveLength(0);
  });

  it("sends the ticket first, and topics only once ready", async () => {
    make().subscribe("a:1", () => {});
    last().onopen();
    await vi.advanceTimersByTimeAsync(0);
    expect(last().sent).toEqual([{ type: "auth", ticket: "t" }]);
    last().say({ type: "ready" });
    expect(last().sent[1]).toEqual({ type: "subscribe", topic: "a:1" });
  });

  it("signals on change and on subscription, so nothing missed in between is lost", async () => {
    const heard = vi.fn();
    make().subscribe("a:1", heard);
    await ready();
    last().say({ type: "subscribed", topic: "a:1" });
    last().say({ type: "changed", topic: "a:1" });
    last().say({ type: "changed", topic: "b:2" });
    last().say({ type: "refused", topic: "a:1" });
    last().onmessage({ data: "{nope" });
    expect(heard).toHaveBeenCalledTimes(2);
  });

  it("shares one socket and one subscription between listeners", async () => {
    const r = make();
    const off = r.subscribe("a:1", () => {});
    r.subscribe("a:1", () => {});
    await ready();
    expect(FakeSocket.all).toHaveLength(1);
    expect(last().sent.filter((m) => m.type === "subscribe")).toHaveLength(1);
    off();
    expect(last().sent.some((m) => m.type === "unsubscribe")).toBe(false);
  });

  it("reconnects with growing delays and subscribes again", async () => {
    make().subscribe("a:1", () => {});
    await ready();
    last().drop();
    await vi.advanceTimersByTimeAsync(999);
    expect(FakeSocket.all).toHaveLength(1);
    await vi.advanceTimersByTimeAsync(1);
    expect(FakeSocket.all).toHaveLength(2);
    last().drop();
    await vi.advanceTimersByTimeAsync(1_999);
    expect(FakeSocket.all).toHaveLength(2);
    await vi.advanceTimersByTimeAsync(1);
    await ready();
    expect(last().sent.at(-1)).toEqual({ type: "subscribe", topic: "a:1" });
  });

  it.each([4401, 4403])("does not hammer the server after %i", async (code) => {
    make().subscribe("a:1", () => {});
    await ready();
    last().drop(code);
    await vi.advanceTimersByTimeAsync(120_000);
    expect(FakeSocket.all).toHaveLength(1);
  });

  it("retries when no ticket can be had", async () => {
    make(() => Promise.reject(new Error("offline"))).subscribe("a:1", () => {});
    last().onopen();
    await vi.advanceTimersByTimeAsync(1_000);
    expect(FakeSocket.all).toHaveLength(2);
  });

  it("closes when idle, but survives a page change", async () => {
    const r = make();
    r.subscribe("a:1", () => {})();
    await ready();
    await vi.advanceTimersByTimeAsync(4_000);
    const off = r.subscribe("b:1", () => {});
    await vi.advanceTimersByTimeAsync(10_000);
    expect(FakeSocket.all).toHaveLength(1);
    expect(last().closed).toBe(false);
    off();
    await vi.advanceTimersByTimeAsync(5_000);
    expect(last().closed).toBe(true);
    await vi.advanceTimersByTimeAsync(60_000);
    expect(FakeSocket.all).toHaveLength(1);
  });

  it("reports its status", async () => {
    const r = make();
    const seen: boolean[] = [];
    r.onStatus(() => seen.push(r.connected));
    r.subscribe("a:1", () => {});
    await ready();
    last().drop();
    expect(seen).toEqual([true, false]);
  });
});
