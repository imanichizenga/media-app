import type { Schemas } from "@news/api-client/admin";
import { ApiError } from "../api";

export type Post = Schemas["Post"];
export type Data = Schemas["PostData"];
export type Text = Schemas["Text"];
export type Locale = "sw" | "en";
export type SaveState =
  | "clean"
  | "dirty"
  | "saving"
  | "saved"
  | "offline"
  | "conflict"
  | "locked"
  | "invalid";
export type Snapshot = { data: Data; post: Post; state: SaveState; error?: unknown; savedAt?: number };
type Deps = {
  save: (version: number, data: Partial<Data>, autosave: boolean) => Promise<Post>;
  delay?: number;
  now?: () => number;
};

type Changes = { fields: Set<keyof Data>; texts: Map<Locale, Set<keyof Text>> };
const none = (): Changes => ({ fields: new Set(), texts: new Map() });

/**
 * What a journalist has typed, and whether the server has it. One request at a time; only what changed is sent;
 * nothing typed is ever replaced by an answer. A network failure keeps trying; a conflict stops and asks.
 */
export class Draft {
  private snapshot: Snapshot;
  private changes = none();
  private inFlight: Promise<boolean> | null = null;
  private timer: ReturnType<typeof setTimeout> | undefined;
  private failures = 0;
  private readonly listeners = new Set<() => void>();

  constructor(
    post: Post,
    private readonly deps: Deps,
  ) {
    this.snapshot = { data: post.data, post, state: "clean" };
  }
  get = () => this.snapshot;
  subscribe = (listener: () => void) => {
    this.listeners.add(listener);
    return () => void this.listeners.delete(listener);
  };
  private set(values: Partial<Snapshot>) {
    this.snapshot = { ...this.snapshot, ...values };
    for (const listener of this.listeners) listener();
  }
  get dirty() {
    return this.changes.fields.size > 0 || this.changes.texts.size > 0;
  }

  change(values: Partial<Omit<Data, "texts">>) {
    for (const key of Object.keys(values)) this.changes.fields.add(key as keyof Data);
    this.touch({ ...this.snapshot.data, ...values });
  }
  changeText(locale: Locale, values: Partial<Text>) {
    const keys = this.changes.texts.get(locale) ?? new Set();
    for (const key of Object.keys(values)) keys.add(key as keyof Text);
    this.changes.texts.set(locale, keys);
    const { data } = this.snapshot;
    this.touch({ ...data, texts: { ...data.texts, [locale]: { ...data.texts?.[locale], ...values } } });
  }
  private touch(data: Data) {
    const stuck = this.snapshot.state === "conflict" || this.snapshot.state === "locked";
    this.set({ data, ...(stuck ? {} : { state: "dirty" }) });
    if (!stuck) this.schedule(this.deps.delay ?? 3_000);
  }
  private schedule(ms: number) {
    clearTimeout(this.timer);
    this.timer = setTimeout(() => void this.flush(true), ms);
  }

  /** Sends everything typed so far. True when the server has all of it. */
  async flush(autosave: boolean): Promise<boolean> {
    clearTimeout(this.timer);
    while (this.inFlight) await this.inFlight;
    if (["conflict", "locked"].includes(this.snapshot.state)) return false;
    if (!this.dirty) return true;
    this.inFlight = this.send(autosave);
    const ok = await this.inFlight;
    this.inFlight = null;
    return ok && (this.dirty && !autosave ? this.flush(false) : true);
  }

  private async send(autosave: boolean): Promise<boolean> {
    const sent = this.changes;
    this.changes = none();
    const { data, post } = this.snapshot;
    const body: Record<string, unknown> = {};
    for (const key of sent.fields) body[key] = data[key];
    if (sent.texts.size)
      body.texts = Object.fromEntries(
        [...sent.texts].map(([locale, keys]) => [
          locale,
          Object.fromEntries([...keys].map((k) => [k, data.texts?.[locale]?.[k]])),
        ]),
      );
    this.set({ state: "saving", error: undefined });
    try {
      const saved = await this.deps.save(post.version, body as Partial<Data>, autosave);
      this.failures = 0;
      this.accept(saved);
      return true;
    } catch (error) {
      for (const key of sent.fields) this.changes.fields.add(key);
      for (const [locale, keys] of sent.texts)
        this.changes.texts.set(locale, new Set([...keys, ...(this.changes.texts.get(locale) ?? [])]));
      const code = error instanceof ApiError ? error.code : "";
      const status = error instanceof ApiError ? error.status : 0;
      const state: SaveState =
        code === "stale_version"
          ? "conflict"
          : code === "locked"
            ? "locked"
            : status >= 400 && status < 500 && status !== 429
              ? "invalid"
              : "offline";
      this.set({ state, error });
      if (state === "offline") this.schedule(Math.min(30_000, 2_000 * 2 ** this.failures++));
      return false;
    }
  }

  /** The server's view of everything we are not editing right now. */
  accept(post: Post) {
    const now = this.deps.now ?? Date.now;
    const data = { ...this.snapshot.data };
    for (const key of Object.keys(post.data) as (keyof Data)[])
      if (key !== "texts" && !this.changes.fields.has(key)) Object.assign(data, { [key]: post.data[key] });
    const texts = { ...post.data.texts };
    for (const [locale, keys] of this.changes.texts) {
      const mine = this.snapshot.data.texts?.[locale] ?? {};
      texts[locale] = { ...texts[locale], ...Object.fromEntries([...keys].map((k) => [k, mine[k]])) };
    }
    data.texts = texts;
    this.set({ post, data, state: this.dirty ? "dirty" : "saved", error: undefined, savedAt: now() });
    if (this.dirty) this.schedule(this.deps.delay ?? 3_000);
  }
  /** Takes over after a lock was taken, keeping what was typed. */
  unlock() {
    this.set({ state: "dirty", error: undefined });
    this.schedule(0);
  }
  destroy() {
    clearTimeout(this.timer);
    this.listeners.clear();
  }
}
